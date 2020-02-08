const { Client } = require('pg')
const client = new Client({
  user : 'postgres',
  host : 'localhost',
  database : 'postgres',
  password : 'postgres',
  port : 5432
})

client.connect()

const getTodos = async ({ id = '', limit = '', page = '', sort = '', orderBy = '' }) => {
  const queryFromStrings = [ ` * ` ]
  const queryWhereStrings = []
  const queryLimitOffsetStrings = []
  const values = []

  if(id) {
    queryWhereStrings.push(` ${0 === queryWhereStrings.length ? 'WHERE' : ''} to_char(id, '99999') LIKE $1` )
    values.push(`%${id}%`)
  }

  if(limit) {
    queryLimitOffsetStrings.push(` LIMIT ${limit} OFFSET 1 `) // TODO calc page.
  }

  const text = 'SELECT ' +
                 queryFromStrings.join(' ') + ' ' +
                 ' FROM TODO ' +
                 queryWhereStrings.join(' ') + ' ' +
                 queryLimitOffsetStrings.join(' ')

  console.log('Debug SQL : ',text)
  const query = {
    name : 'fetch-todo',
    text,
    values
  }

  const todos = await new Promise((resolve, reject) => {
    client.query(query, (err, res) => {
      if(err) {
        reject(err.stack)
        return
      }

      resolve(res.rows)
    })
  })

  const totalCount await new Promise((resolve, reject) => {
    client.query({
      name : 'fetch-todo-total-count',
      text : 'SELECT (*) AS total FROM TODO ' + queryWhereStrings.join(' '),
      values
    }, (err, res) => {
      if(err) {
        reject(err.stack)
        return
      }

      resolve(res.rows[0].total)
    })
  })

  return { todos, totalCount }
}

module.exports.getTodos = getTodos
