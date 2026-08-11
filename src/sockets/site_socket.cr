struct SiteSocket < Amber::WebSockets::ClientSocket
  channel "site:*", SiteProofChannel

  def on_connect : Bool
    true
  end
end
