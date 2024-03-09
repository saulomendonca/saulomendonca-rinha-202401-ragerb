require "sequel"

module Database
  def self.init!
    return if @connection

    # @connection ||= Sequel.sqlite('blog2.sqlite')
    # Sequel.postgres('blog', host: 'localhost', user: 'user', password: 'password')
    # Sequel.connect(
    #   "postgres://user:password@host:port/database_name",
    #   # ENV["DATABASE_URL"],
    #   max_connections: 10,
    #   # max_connections: ENV.fetch("MAX_DATABASE_CONNECTIONS", 5),
    #   logger: Logger.new(STDOUT)
    # )

    @connection = Sequel.connect(
      ENV["DATABASE_URL"] || "postgres://postgres:postgres@localhost:5432/rinha2024",
      max_connections: 10,
      logger: nil
    )

    create_db(@connection)

    @connection
  end

  def self.connection
    init!

    @connection
  end

  def self.create_db(db)
    return if db.table_exists?(:clients)

    db.run(<<-SQL
      CREATE TABLE public.clients (
        id bigserial NOT NULL,
        "name" varchar NULL,
        account_limit int4 NULL,
        account_balance int4 DEFAULT 0 NULL,
        CONSTRAINT clients_pkey PRIMARY KEY (id)
      );
    SQL
    )

    db.run(<<-SQL
      CREATE TABLE public.transactions (
        id bigserial NOT NULL,
        amount int4 NULL,
        transaction_type varchar NULL,
        description varchar NULL,
        transaction_date timestamp(6) DEFAULT CURRENT_TIMESTAMP NOT NULL,
        client_id int8 NOT NULL,
        CONSTRAINT transactions_pkey PRIMARY KEY (id)
      );
      CREATE INDEX index_transactions_on_client_id ON public.transactions USING btree (client_id);

      ALTER TABLE public.transactions ADD CONSTRAINT fk_rails_2fe9d6a78f FOREIGN KEY (client_id) REFERENCES public.clients(id);
      SQL
    )

    clients = db[:clients]

    # populate the table
    clients.insert(id: 1, name: 'o barato sai caro', account_limit: 1_000_00 )
    clients.insert(id: 2, name: 'zan corp ltda', account_limit: 800_00)
    clients.insert(id: 3, name: 'les cruders', account_limit: 10_000_00)
    clients.insert(id: 4, name: 'padaria joia de cocaia', account_limit: 100_000_00)
    clients.insert(id: 5, name: 'kid mais', account_limit: 5_000_0)
  end
end
