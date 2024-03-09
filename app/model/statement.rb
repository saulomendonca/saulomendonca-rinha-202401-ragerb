require './app/infra/database'
class Statement
    def initialize(cliente_id)
      @cliente_id = cliente_id
    end

    def show
      db = Database.connection
      client_data =  db[:clients].where(id: @cliente_id).get([:id])
      return if client_data.nil?

      db[statement_sql].first[:statement]
    end

    private

    def statement_sql
      <<-SQL
      SELECT
        jsonb_build_object(
          'saldo', json_build_object(
            'total', account_balance ,
            'data_extrato', current_timestamp,
            'limite', account_limit
          ),
          'ultimas_transacoes', jsonb_agg_strict(transactions)
        )
      AS statement
      FROM public.clients
      LEFT JOIN (
        SELECT
          amount AS "valor",
          transaction_type AS  "tipo",
          description AS "descricao",
          transaction_date AS  "realizada_em"
        FROM public.transactions
        WHERE client_id = #{@cliente_id}
        ORDER BY id DESC
        LIMIT 10
      ) transactions ON true
      WHERE id = #{@cliente_id}
      GROUP BY clients.account_balance, clients.account_limit
      SQL
    end
end
