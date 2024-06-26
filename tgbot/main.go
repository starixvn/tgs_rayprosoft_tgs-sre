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

    bot, err := tele.NewBot(tele.Settings{
        Token:  botToken,
        Poller: &tele.LongPoller{Timeout: 10 * time.Second},
    })
    if err != nil {
        log.Fatal(err)
        return
    }

    // 監聽 /changewaf 命令
    bot.Handle("/changewaf", func(m *tele.Message) {
        domains := strings.Fields(m.Payload)
        if len(domains) == 0 {
            bot.Send(m.Chat, "请提供至少一个域名。用法: /changewaf domain1 [domain2] [domain3] ...")
            return
        }

        // 執行 shell 並输出結果訊息
        cmd := exec.Command("/bin/bash", append([]string{"/home/shawn/tgs-sre/tgbot/scripts/cloudflare-waf.sh"}, domains...)...)
        output, err := cmd.CombinedOutput()
        
        // 输出訊息到 Telegram
        if err != nil {
            bot.Send(m.Chat, "执行出错: "+err.Error()+"\nOutput: "+string(output))
        } else {
            bot.Send(m.Chat, "执行结果: "+string(output))
        }
    })
    bot.Handle("/clearcache", func(m *tele.Message) {
        domains := strings.Fields(m.Payload)
        if len(domains) == 0 {
            bot.Send(m.Chat, "请提供至少一个域名。用法: /clearcache domain1 [domain2] [domain3] ...")
            return
        }

        // 監聽 shell 並输出結果訊息
        cmd := exec.Command("/bin/bash", append([]string{"/home/shawn/tgs-sre/tgbot/scripts/clearcache.sh"}, domains...)...)
        output, err := cmd.CombinedOutput()

        // 输出訊息到 Telegram
        if err != nil {
            bot.Send(m.Chat, "执行出错: "+err.Error()+"\nOutput: "+string(output))
        } else {
            bot.Send(m.Chat, "执行结果: "+string(output))
        }
    })

    bot.Start()
}

