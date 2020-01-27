const sqlite3 = require('sqlite3')

let database

class BaseRepository {
  static init() {
    database = new sqlite3.Database('user.sqlite3')
  }

  static get() {
    return database
  }
}

module.exports = BaseRepository