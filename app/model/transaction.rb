require './app/infra/database'
class Transaction
    def initialize(id, valor, tipo, descricao)
      @cliente_id = id
      @valor = valor
      @tipo = tipo
      @descricao = descricao
    end

    def create
      return %i[failure invalid_transaction] unless valid?

      db = Database.connection
      client_data =  db[:clients].where(id: @cliente_id).get([:id, :account_balance, :account_limit])
      return %i[failure client_not_found] if client_data.nil?

      id, saldo_conta, limite = client_data

      has_limit = @tipo == 'd' && @valor > (saldo_conta + limite)
      return %i[failure invalid_transaction] if has_limit


      begin
        db.transaction do # BEGIN
          insert_transaction(db)
          result = update_client_balance(db)
          return [:success, result]
        end
      rescue StandardError => e
        %i[failure invalid_transaction]
      end
    end

    private
    def valid?
      return unless @valor.kind_of?(Integer) && @valor > 0
      return unless %w[c d].include? @tipo
      return if @descricao.nil? || !@descricao.size.between?(1,10)
      true
    end

    def insert_transaction(db)
      db[:transactions].insert(
        amount: @valor,
        transaction_type: @tipo,
        description: @descricao,
        client_id: @cliente_id
      )
    end

    def update_client_balance(db)
      update_query = @tipo == 'c' ? update_client_balance_credit_sql : update_client_balance_debit_sql
      result = db[update_query].first

      raise RuntimeError if result.nil?

      result
    end

    def update_client_balance_credit_sql
      <<-SQL
        UPDATE clients
          SET account_balance = account_balance + #{@valor}
        WHERE id = #{@cliente_id}
        RETURNING account_limit AS limite, account_balance AS saldo
      SQL
    end

    def update_client_balance_debit_sql
      <<-SQL
        UPDATE clients
          SET account_balance = account_balance - #{@valor}
        WHERE id = #{@cliente_id}
          AND (account_balance + account_limit >= #{@valor})
        RETURNING account_limit AS limite, account_balance AS saldo
      SQL
    end
end
