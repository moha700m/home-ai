import { defineEval, includes } from "@cursor/bdk/evals";

export default defineEval({
  tags: ["smoke"],
  cases: [
    {
      id: "capability",
      description: "Asks for PC capability and uses pc_specs.",
      async test(t) {
        await t.send("وش قدرة جهازي؟ وش أقدر أشغّل محلياً؟");
        t.succeeded();
        t.calledTool("pc_specs");
        t.check(t.reply, includes(/light|medium|strong|رام|GiB|جهاز/i));
      },
    },
  ],
});
