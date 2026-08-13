class SiteProofChannel < Amber::WebSockets::Channel
  TOPIC = "site:proof"

  def handle_message(client_socket, msg)
    return unless msg["subject"]?.try(&.as_s?) == "site:probe"

    client_socket.socket.send({
      "event"   => "site:ready",
      "topic"   => TOPIC,
      "payload" => {"connections" => presence_count.to_s},
    }.to_json)
  end

  def after_join(client_socket)
    self.class.broadcast_to(
      TOPIC,
      "site:ready",
      {"connections" => presence_count.to_s}
    )
  end

  def after_leave(client_socket)
    self.class.broadcast_to(
      TOPIC,
      "site:presence",
      {"connections" => presence_count.to_s}
    )
  end
end
