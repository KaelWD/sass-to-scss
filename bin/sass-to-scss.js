#!/usr/bin/env node
import path from 'node:path'
import process from 'node:process'
import fs from 'node:fs/promises'
import { Writable } from 'node:stream'
import MagicString from 'magic-string'
import { x } from 'tinyexec'
import { glob } from 'tinyglobby'
import { parseArgs } from 'node:util'

const args = parseArgs({
  options: {
    'dry-run': {
      type: 'boolean',
      short: 'n',
    },
    exclude: {
      type: 'string',
      multiple: true,
    }
  },
})

;(async function main () {
  const paths = await glob(['**/*.sass', '**/*.vue'], {
    ignore: ['**/node_modules/**'].concat(...args.values.exclude),
    cwd: process.cwd(),
  })

  for (const file of paths) {
    const start = performance.now()
    printStart(file)
    try {
      if (path.extname(file) === '.vue') {
        await transformVue(file)
      } else {
        await transformFile(file)
      }
    } catch (err) {
      process.stdout.write('\n')
      throw err
    }
    printDone(file, start)
  }
})()

function printStart (file) {
  if (process.stdout.isTTY) {
    process.stdout.write('🔃 ' + file)
  } else {
    process.stdout.write(file + ' ...')
  }
}

function printDone (file, start) {
  const time = performance.now() - start
  if (process.stdout.isTTY) {
    process.stdout.write(`\x1B[1K\r✅  ${file} (${time.toFixed(0)}ms)\n`)
  } else {
    process.stdout.write(`done (${time.toFixed(0)}ms)\n`)
  }
}

let vue
async function transformVue (filename) {
  if (!vue) {
    try {
      vue = await import('vue/compiler-sfc').then(m => m.parse)
    } catch (err) {
      console.log(err)
      return []
    }
  }

  const source = await fs.readFile(filename, 'utf-8')
  const result = vue(source, { filename }).descriptor.styles

  const s = new MagicString(source)
  for (const block of result) {
    if (block.lang !== 'sass') continue
    const out = await sassToScss({ source: block.content, filename })
    {
      const searchRange = source.lastIndexOf('<', block.loc.start.offset)
      const searchText = source.slice(searchRange, block.loc.start.offset)
      const match = /lang=["']?sass["']?/g.exec(searchText)
      if (!match) throw new Error('Unrecognised "lang" attribute format')
      const start = match.index + searchRange
      const end = start + match[0].length
      s.update(start, end, 'lang="scss"')
    }
    s.update(block.loc.start.offset, block.loc.end.offset, '\n' + out)
  }

  if (!args.values['dry-run']) {
    await fs.writeFile(filename, s.toString(), 'utf-8')
  }
}

async function transformFile (filename) {
  const out = await sassToScss({ filename })
  if (!args.values['dry-run']) {
    await fs.writeFile(filename.replace(/\.sass$/, '.scss'), out, 'utf-8')
  }
}

async function sassToScss ({ source, filename }) {
  const arg = [filename]
  if (source) arg.push('--stdin')
  const result = x(path.resolve(import.meta.dirname, '../dist/sass-to-scss'), arg)
  if (source) {
    await ReadableStream.from([source]).pipeTo(Writable.toWeb(result.process.stdin))
  }
  const out = await result
  if (out.exitCode) {
    throw new Error(out.stderr)
  }
  return out.stdout
}
