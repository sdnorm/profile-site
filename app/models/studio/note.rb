module Studio
  # A short article under /notes. Tableless: the list is fixed, and each note's body is an ERB template.
  Note = Data.define(:slug, :title, :description) do
    def self.all = Note::LIST

    # Looks the slug up by equality in the fixed list. Nothing is built from the argument.
    def self.find(slug) = Note::LIST.find { |note| note.slug == slug }

    def template = "studio/notes/#{slug.underscore}"
  end

  Note::LIST = [
    Note.new(
      slug: "what-leaves-your-business",
      title: "What actually leaves your business when you use an AI tool",
      description: "What an AI tool sends to its provider, what stays put, and the questions to ask before you paste in customer data."
    ),
    Note.new(
      slug: "your-server-or-the-vendors",
      title: "Your own server or the vendor's: where an AI agent should run",
      description: "When an AI agent can run on the vendor's hosted service, and when it is worth putting it on a server you own."
    )
  ].freeze
end
