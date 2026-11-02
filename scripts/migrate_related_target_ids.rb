#!/usr/bin/env ruby
# frozen_string_literal: true

# Point same-edition relationships at clause ids. The ed3 import wrote a
# specialization's target as its markdown link ("[vehicle](vehicle.md)")
# and left subClassOf and property targets with no id at all, so nothing
# could link to them. The target is resolved by the preferred term of a
# concept in the same dataset; a target with no concept (e.g. owl::Thing)
# keeps only its content. Duplicate entries are dropped. Idempotent.
#
# Usage: ruby scripts/migrate_related_target_ids.rb datasets/isotc204-ed3/

require "yaml"

def key(name)
  name.to_s.downcase.gsub(/[^a-z0-9]/, "")
end

# "[ADS-equipped vehicle](ADS-equipped vehicle.md)" -> "ADS-equipped vehicle"
# "subClassOf [some materialEntity]"                -> "materialEntity"
def target_name(rel)
  id = rel.dig("ref", "id").to_s
  return id[/\A\[([^\]]+)\]/, 1] if id.start_with?("[")

  rel.dig("content", "eng").to_s[/\[([^\]]*)\]\z/, 1].to_s.split.last
end

ARGV.each do |dir|
  files = Dir.glob(File.join(dir, "concepts", "*.yaml")).sort
  urn = YAML.load_file(File.join(dir, "register.yaml")).fetch("urn")

  clauses = {}
  files.each do |f|
    YAML.load_stream(File.read(f)) do |doc|
      next unless doc.is_a?(Hash) && doc.dig("data", "language_code")

      term = Array(doc.dig("data", "terms")).first
      clauses[key(term["designation"])] ||= File.basename(f, ".yaml") if term
    end
  end

  changed = 0
  unresolved = 0
  files.each do |f|
    text = File.read(f)
    docs = YAML.load_stream(text)
    rels = docs.first.is_a?(Hash) ? docs.first["related"] : nil
    next unless rels.is_a?(Array)

    before = Marshal.load(Marshal.dump(rels))
    rels.each do |r|
      ref = r["ref"]
      next unless ref.is_a?(Hash) && ref["source"] == urn
      next if clauses.value?(ref["id"])

      clause = clauses[key(target_name(r))]
      if clause
        ref["id"] = clause
      else
        ref.delete("id")
        unresolved += 1
      end
    end
    rels.uniq!
    next if rels == before

    # Rewrite only the managed concept; the localized documents after it
    # are left byte for byte.
    rest = text.index("\n---\n", 4)
    File.write(f, YAML.dump(docs.first) + text[(rest + 1)..])
    changed += 1
  end
  puts "#{dir}: migrated #{changed}/#{files.size} files, #{unresolved} targets with no concept"
end
