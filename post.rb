require 'sqlite3'

class Post
  @@SQLite_DB_file = 'notepad.db'
  puts "Файл не найден" unless File.exist?(@@SQLite_DB_file)

  def self.post_types
    { 'Memo' => Memo, 'Task' => Task, 'Link' => Link }
  end

  def self.create(type)
    post_types[type].new
  end

  def self.find_by_id(id)
    db = SQLite3::Database.open(@@SQLite_DB_file)

    db.results_as_hash = true

    result = db.execute("SELECT * FROM posts WHERE rowid = ?", id)


    if result.empty?
      puts "Такой id #{id} не найден в базе "
      db.close
      abort
    else
      result = result[0] if result.is_a? Array
      db.close

      post = create(result['type'])

      post.load_data(result)

      post
    end
  end

  def self.find_all(limit, type)
    db = SQLite3::Database.open(@@SQLite_DB_file)
    # db.results_as_hash = false

    query = "SELECT rowid, * FROM posts "

    query += "WHERE type = :type " unless type.nil?
    query += "ORDER by rowid DESC "

    query += "LIMIT :limit " unless limit.nil?

    statement = db.prepare(query)

    statement.bind_param('type', type) unless type.nil?
    statement.bind_param('limit', limit) unless limit.nil?

    result = statement.execute!

    statement.close
    db.close
    result
  end

  def initialize
    @created_at = Time.now
    @text = nil
  end

  def read_from_console
    # todo
  end

  def to_strings
    # todo
  end

  def save
    file = File.new(file_path, "w:UTF-8")
    to_strings.each { |str| file.puts(str) }
    file.close
  end

  def file_path
    current_path = File.dirname(__FILE__)

    file_time = @created_at.strftime('%Y-%m-%d_%H-%M-%S')

    "#{current_path}/#{self.class.name}_#{file_time}.txt"
  end

  def save_to_db
    db = SQLite3::Database.open(@@SQLite_DB_file)
    db.results_as_hash = true

    db.execute(
      "INSERT INTO posts (" +
        to_db_hash.keys.join(', ') +
        ")" +
        " VALUES (" +
        ('?,' * to_db_hash.keys.size).chomp(',') +
        ")",
      to_db_hash.values
    )

    insert_row_id = db.last_insert_row_id
    db.close
    insert_row_id
  end

  def to_db_hash
    {
      'type' => self.class.name,
      'created_at' => @created_at.to_s
    }
  end

  def load_data(data_hash)
    @created_at = Time.parse(data_hash['created_at'])
  end
end
