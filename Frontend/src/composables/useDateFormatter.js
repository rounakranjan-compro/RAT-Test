
export function useDateFormatter() {

    const formatDateTime = (date = new Date()) => {
    const dateStr = new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: '2-digit',
      year: 'numeric',
    }).format(date)

    const timeStr = new Intl.DateTimeFormat('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true,
    }).format(date)

    return `${dateStr} • ${timeStr}`
  }

 
  const getCurrentTimestamp = () => {
    return formatDateTime(new Date())
  }

  return {
    formatDateTime,
    getCurrentTimestamp
  }
}
