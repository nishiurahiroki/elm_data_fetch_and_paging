const { Client } = require('pg')
const client = new Client({
  user : 'postgres',
  host : 'localhost',
  database : 'postgres',
  password : 'postgres',
  port : 5432
})

client.connect()

const getTodos = ({ id = '', limit = '', page = '', sort = '', orderBy = '' }) => {
  const queryFromStrings = [ 'SELECT * FROM TODO' ]
  const queryWhereStrings = []
  const values = []

  if(id) {
    queryWhereStrings.push(` ${0 === queryWhereStrings.length ? 'WHERE' : ''} to_char(id, '99999') LIKE $1` )
    values.push(`%${id}%`)
  }

  const query = {
    name : 'fetch-todo',
    text : queryFromStrings.join(' ') + ' ' +
           queryWhereStrings.join(' '),
    values
  }

  return new Promise((resolve, reject) => {
    client.query(query, (err, res) => {
      if(err) {
        reject(err.stack)
        return
      }
      
      resolve(res.rows)
    })
  })
}

module.exports.getTodos = getTodos
