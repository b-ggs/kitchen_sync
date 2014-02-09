require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class SnapshotFromTest < KitchenSync::EndpointTestCase
  include TestTableSchemas

  def from_or_to
    :from
  end

  test_each "accepts the without_snapshot command for solo from endpoints after the protocol negotation, and returns nil to show its completed" do
    clear_schema
    create_footbl # arbitrary, just something to show the schema was loaded successfully

    send_protocol_command
    assert_equal nil, send_command(Commands::WITHOUT_SNAPSHOT)
    assert_equal({"tables" => [footbl_def]}, send_command(Commands::SCHEMA))
  end

  test_each "gives back a string from the export_snapshot command, and accepts that string in another worker" do
    clear_schema
    create_footbl # arbitrary, just something to show the schema was loaded successfully

    send_protocol_command
    snapshot = send_command(Commands::EXPORT_SNAPSHOT)
    assert_instance_of String, snapshot
    extra_spawner = KitchenSyncSpawner.new(binary_path, program_args, :capture_stderr_in => captured_stderr_filename).tap(&:start_binary)
    begin
      extra_spawner.send_command(Commands::PROTOCOL, CURRENT_PROTOCOL_VERSION)
      assert_equal nil, extra_spawner.send_command(Commands::IMPORT_SNAPSHOT, snapshot)
      assert_equal({"tables" => [footbl_def]}, extra_spawner.send_command(Commands::SCHEMA))
    ensure
      extra_spawner.stop_binary
    end
    assert_equal nil, send_command(Commands::UNHOLD_SNAPSHOT)
    assert_equal({"tables" => [footbl_def]}, send_command(Commands::SCHEMA))
  end
end
