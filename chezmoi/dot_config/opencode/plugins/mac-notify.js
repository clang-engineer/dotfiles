const APP_NAME = "OpenCode"
const TERMINAL = "ghostty"
const MESSAGE = "Agent 작업 완료"

export const MacNotify = async ({ client }) => ({
  async event({ event }) {
    if (event?.type !== "session.idle") return
    try {
      const session = await client.session.get({ path: { id: event.properties.sessionID } })
      if (session?.parentID) return
      const front = (await Bun.spawn([
        "/usr/bin/osascript",
        "-e",
        'tell application "System Events" to get name of first application process whose frontmost is true',
      ]).text()).trim().toLowerCase()
      if (front === TERMINAL) return
    } catch {}
    Bun.spawn(["/usr/bin/osascript", "-e", `display notification "${MESSAGE}" with title "${APP_NAME}"`])
  },
})