export const chunkArray = <T>(array: T[], size: number): T[][] => {
  const result = [];
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size));
  }
  return result;
};

// Add config for schedule frequency if needed. Default is every 1 minute.
export const SCHEDULE_FREQUENCY = process.env.SCHEDULE_FREQUENCY || "every 1 minutes";
