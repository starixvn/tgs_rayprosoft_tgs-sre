package main

import (
    "log"
    "os"
    "os/exec"
    "strconv"
    "strings"
    "time"

    tele "gopkg.in/tucnak/telebot.v2"
)

func main() {
    botToken := os.Getenv("TG_TOKEN")
    if botToken == "" {
        log.Fatal("未设置 Telegram bot token")
    }

    chatIDStr := os.Getenv("CHAT_ID")
    if chatIDStr == "" {
        log.Fatal("未设置 chat ID")
    }
    // 转换 CHAT_ID 从 string 到 int64
    chatID, err := strconv.ParseInt(chatIDStr, 10, 64)
    if err != nil {
        log.Fatalf("Chat ID 转换错误: %v", err)
    }

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
            bot.Send(tele.ChatID(chatID), "请提供至少一个域名。用法: /changewaf domain1 [domain2] [domain3] ...")
            return
        }
        cmd := exec.Command("/bin/bash", append([]string{"/home/shawn/tgbot/scripts/clouflare-waf.sh"}, domains...)...)
        output, err := cmd.CombinedOutput()
        if err != nil {
            bot.Send(tele.ChatID(chatID), "执行出错: "+err.Error()+"\nOutput: "+string(output))
            return
        }
        bot.Send(tele.ChatID(chatID), "执行结果: "+string(output))
    })

    bot.Start()
}

