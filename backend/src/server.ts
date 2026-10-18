console.info('EasyRail Backend is running in Docker!');

// Не дає процесу Node.js завершитися, друкуючи статус кожні 10 секунд
setInterval(() => {
	console.info('Still alive...');
}, 10000);
