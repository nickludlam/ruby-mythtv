module MythTV
  
  # Map the protocol versions to the number of properties of
  # recording objects
  PROTOCOL_MAPPING = [
    { :protocol_version => 31, :recording_elements => 35 },
    { :protocol_version => 40, :recording_elements => 46 }
  ]
  
  # Set the default protocol version to announce. Should
  # track the latest release
  DEFAULT_PROTOCOL_VERSION = 40

end