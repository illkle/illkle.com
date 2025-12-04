import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";
import { techNames } from "@components/tech-logos/logos";

const blog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/blog" }),
  schema: z.object({
    title: z.string().optional(),
    date: z.string().optional(),
    tags: z.array(z.string()).optional(),
  }),
});

const projects = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/data/projects" }),
  schema: ({ image }) =>
    z.object({
      title: z.string().optional(),
      views: z
        .array(
          z.object({
            label: z.string().optional(),
            link: z.string(),
            image: image().optional(),
          }),
        )
        .optional(),
      year: z.number().or(z.string()).optional(),
      link: z.string().optional(),
      tech: z.array(techNames).optional(),
      flags: z.array(z.string()).optional(),
      position: z.number().optional(),
      links: z
        .array(z.object({ link: z.string(), label: z.string() }))
        .optional(),
    }),
});

export const collections = { projects };
