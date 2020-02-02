const express = require('express')
const app = express()
const bodyParser = require('body-parser')

const { getTodos } = require('../repository/TodoRepository.js')

app.use(bodyParser.urlencoded({ extended : true }))

app.use(bodyParser.json())
const startServer = () => {
  app.get('/api/v1/todo', async (req, res) => {
    // TODO parameter
    const todos = await getTodos({})
    res.json({
      result : todos
    })
  })

  app.listen(8000)
}

module.exports.startServer = startServer
