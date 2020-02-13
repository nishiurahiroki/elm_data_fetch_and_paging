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
    const offset = (limit * page) - limit
    queryLimitOffsetStrings.push(` LIMIT ${limit} OFFSET ${offset} `) // TODO calc page.
  }

  const text = 'SELECT ' +
                 queryFromStrings.join(' ') + ' ' +
                 ' FROM TODO ' +
                 queryWhereStrings.join(' ') + ' ' +
                 queryLimitOffsetStrings.join(' ')

  console.log('Debug SQL : ',text)

  const todos = await new Promise((resolve, reject) => {
    client.query(text, values, (err, res) => {
      if(err) {
        reject(err.stack)
        return
      }

      resolve(res.rows)
    })
  })


  const {totalCount, totalPage} = await new Promise((resolve, reject) => {
    client.query('SELECT COUNT(*) AS total FROM TODO ' + queryWhereStrings.join(' '),
      values, (err, res) => {
        if(err) {
          reject(err.stack)
          return
        }

        resolve({
          totalCount : Number(res.rows[0].total),
          totalPage : Math.floor(res.rows[0].total / limit)
        })
    })
  })

  return { todos, totalCount, totalPage }
}

module.exports.getTodos = getTodos
