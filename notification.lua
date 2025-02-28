local love = require("love")

-- notification.lua - Handles game notifications

-- Enum for notification positions
NotificationPosition = {
    TOP = "top",
    MIDDLE = "middle",
    BOTTOM = "bottom"
}

-- Enum for notification types
NotificationType = {
    TURN = "turn",
    RESOURCE = "resource",
    WARNING = "warning",
    ACHIEVEMENT = "achievement"
}

Notification = {}
Notification.__index = Notification

function Notification.new()
    local self = setmetatable({}, Notification)

    -- Queue of active notifications
    self.notifications = {}

    -- Default settings
    self.defaultDuration = 1.5
    self.maxNotifications = 3  -- Maximum number of notifications to show at once
    self.padding = 16  -- Padding around text (in pixels)
    self.minWidth = 120  -- Minimum width for notifications

    return self
end

-- Add a new notification to the queue
function Notification:show(text, options)
    options = options or {}

    -- Calculate width based on text length
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    -- Width is text width plus padding on both sides, with a minimum width
    local width = math.max(self.minWidth, textWidth + (self.padding * 2))
    -- Height is text height plus padding on both sides
    local height = textHeight + (self.padding * 2)

    local notification = {
        text = text,
        timer = options.duration or self.defaultDuration,
        duration = options.duration or self.defaultDuration,
        color = options.color or {0.7, 0.7, 1.0},  -- Default to light blue
        backgroundColor = options.backgroundColor or {0, 0, 0, 0.7},
        position = options.position or NotificationPosition.TOP,
        width = options.width or width,
        height = options.height or height,
        active = true,
        textWidth = textWidth,  -- Store text dimensions for centering
        textHeight = textHeight
    }

    -- Add to the queue
    table.insert(self.notifications, notification)

    -- Limit the number of notifications
    while #self.notifications > self.maxNotifications do
        table.remove(self.notifications, 1)
    end

    return notification
end

-- Update all active notifications
function Notification:update(dt)
    local i = 1
    while i <= #self.notifications do
        local notification = self.notifications[i]

        notification.timer = notification.timer - dt

        if notification.timer <= 0 then
            table.remove(self.notifications, i)
        else
            i = i + 1
        end
    end
end

-- Draw all active notifications
function Notification:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    for i, notification in ipairs(self.notifications) do
        -- Calculate position based on notification settings
        local x = screenWidth / 2 - notification.width / 2
        local y

        if notification.position == NotificationPosition.TOP then
            y = 50 + (i - 1) * (notification.height + 10)
        elseif notification.position == NotificationPosition.BOTTOM then
            y = screenHeight - 50 - notification.height - (i - 1) * (notification.height + 10)
        else -- middle
            y = screenHeight / 2 - notification.height / 2
        end

        -- Calculate alpha based on remaining time
        local alpha = math.min(1, notification.timer / (notification.duration / 2))
        if notification.timer < notification.duration / 2 then
            alpha = notification.timer / (notification.duration / 2)
        end

        -- Draw background
        love.graphics.setColor(
            notification.backgroundColor[1],
            notification.backgroundColor[2],
            notification.backgroundColor[3],
            (notification.backgroundColor[4] or 1) * alpha
        )
        love.graphics.rectangle("fill", x, y, notification.width, notification.height)

        -- Draw border
        love.graphics.setColor(
            notification.color[1],
            notification.color[2],
            notification.color[3],
            alpha
        )
        love.graphics.rectangle("line", x, y, notification.width, notification.height)

        -- Use stored text dimensions for perfect centering
        local textX = x + notification.width/2 - notification.textWidth/2
        local textY = y + notification.height/2 - notification.textHeight/2

        -- Draw text shadow
        love.graphics.setColor(0, 0, 0, 0.5 * alpha)
        love.graphics.print(notification.text, textX + 1, textY + 1)

        -- Draw text
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(notification.text, textX, textY)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Notification
