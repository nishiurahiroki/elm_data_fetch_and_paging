const sqlite3 = require('sqlite3')

let database

class UserRepository {
  static init() {
    database = new sqlite3.Database('user.sqlite3')
  }

  static get() {
    return database
  }

  static async createTableIfNotExists() {
    const db = UserRepository.get()
    return new Promise((resolve, reject) => {
      try {
        db.serialize(() => {
          db.run(`create table if not exists user (
            id number primary key,
            name text
          )`)
        })
        return resolve()
      } catch (err) {
        return reject(err)
      }
   })
  }

  static async create({id, name}) {
    const db = UserRepository.get()
    return new Promise((resolve, reject) => {
      try {
        db.run(`insert or replace into ${userTableName}
        (account, name, email)
        values ($account, $name, $email)`,
          user.account, user.name, user.email
        )
        return resolve()
      } catch (err) {
        return reject(err)
      }
    })
  }
}

module.exports = UserRepository