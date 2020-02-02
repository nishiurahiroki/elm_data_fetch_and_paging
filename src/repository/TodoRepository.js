const { Client } = require('pg')
const client = new Client({
  user : 'postgres',
  host : 'localhost',
  database : 'postgres',
  password : 'postgres',
  port : 5432
})

client.connect()

const getTodos = ({ limit = '', page = '', sort = '', orderBy = '' }) => {
  const queryStrings = [ 'SELECT * FROM TODO' ]
  // TODO Use query parameter.
  return new Promise((resolve, reject) => {
    client.query(queryStrings.join(' '), (err, res) => {
      resolve(err ? err.stack : res.rows)
      client.end()
    })
  })
}

module.exports.getTodos = getTodos
