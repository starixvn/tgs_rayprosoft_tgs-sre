package main

import (
    "log"
    "os/exec"
    "strings"
    "time"
    tele "gopkg.in/tucnak/telebot.v2"
)

func main() {
    const botToken = "6073328484:AAHKIDTpNDnK79-J6cEh0dSGXx-_wumwB9E"

    // 转换 CHAT_ID 从 string 到 int64

    bot, err := tele.NewBot(tele.Settings{
        Token:  botToken,
        Poller: &tele.LongPoller{Timeout: 10 * time.Second},
    })
    if err != nil {
        log.Fatal(err)
        return
    }

    // 处理 /changewaf 命令
    bot.Handle("/changewaf", func(m *tele.Message) {
        domains := strings.Fields(m.Payload)
        if len(domains) == 0 {
            bot.Send(m.Chat, "请提供至少一个域名。用法: /changewaf domain1 [domain2] [domain3] ...")
            return
        }
        cmd := exec.Command("/bin/bash", append([]string{"/home/shawn/tgbot/scripts/clouflare-waf.sh"}, domains...)...)
        output, err := cmd.CombinedOutput()
        if err != nil {
            bot.Send(m.Chat, "执行出错: "+err.Error()+"\nOutput: "+string(output))
            return
        }
        bot.Send(m.Chat, "执行结果: "+string(output))
    })

    bot.Start()
}
