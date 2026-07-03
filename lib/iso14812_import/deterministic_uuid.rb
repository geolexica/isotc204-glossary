# frozen_string_literal: true

require "openssl"

# Minimal, self-contained UUIDv5 implementation.
#
# We don't use +Glossarist::Utilities::UUID.uuid_v5+ because it depends on
# ActiveSupport's +MatchData#present?+ (via +pack_uuid_namespace+), which
# isn't loaded in our bundle and shouldn't be required for a UUID routine.
# Once that upstream bug is fixed and the gem releases, we can switch back.
#
# Algorithm: RFC 4122 §4.3 (SHA-1 variant).
module Iso14812Import
  module DeterministicUuid
    # Fixed project namespace. Combined with <edition-urn>:<clause> names,
    # produces stable UUIDs distinct per (edition, concept).
    PROJECT_NAMESPACE = "7c3f1b24-9c8e-5d7a-b6e4-2f1a8c5b9d03".freeze

    def self.for_edition_and_name(edition_urn, name)
      uuid_v5(PROJECT_NAMESPACE, "#{edition_urn}:#{name}")
    end

    def self.uuid_v5(namespace_uuid, name)
      namespace_bytes = parse_uuid_bytes(namespace_uuid)
      hash = OpenSSL::Digest::SHA1.digest(namespace_bytes + name.to_s)
      format_uuid(hash)
    end

    def self.parse_uuid_bytes(uuid_str)
      hex = uuid_str.to_s.delete("-")
      raise ArgumentError, "invalid UUID: #{uuid_str}" unless hex.match?(/\A\h{32}\z/)

      [hex].pack("H*")
    end
    private_class_method :parse_uuid_bytes

    def self.format_uuid(hash)
      bytes = hash[0, 16].bytes
      bytes[6] = (bytes[6] & 0x0F) | 0x50   # version 5
      bytes[8] = (bytes[8] & 0x3F) | 0x80   # RFC 4122 variant
      format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", *bytes)
    end
    private_class_method :format_uuid
  end
end
