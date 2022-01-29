import { marked } from 'marked';

const getMarkdown = async (path: string): Promise<string> => {
	const text = await import(path + '?raw');

	return marked(text.default);
};

export default getMarkdown;
