#!/usr/bin/env -S deno run --allow-all --ext ts

import * as mod from 'https://deno.land/std@0.209.0/assert/mod.ts';
import 'https://deno.land/x/dax_extras@2.3.0-0.36.0/mod.ts';

enum FileType {
  SCSS = 'scss',
  TS = 'ts',
  TEST = 'test',
  HTML = 'html',
  BUILD = 'build',
  HARNESS = 'harness',
}

function main(filename: string, convertTo: FileType): string {
  const matchFileExtension =
    /(_test\.ts|\.ts|\.scss|\.ng\.html|BUILD|_harness.ts)$/;
  const matchFileName = new RegExp(`\/[^/]*${matchFileExtension.source}`);
  let path = filename.replace(matchFileName, '');

  if (filename.includes('_harness.ts')) {
    filename = filename.replace(new RegExp('(.*/)testing/(.*)'), '$1$2');
    // Remove the double "testing" dir path for harness to harness case
    path = path.replace('testing', '');
  }

  switch (convertTo) {
    case FileType.SCSS:
      return filename.replace(matchFileExtension, '.scss');
    case FileType.TS:
      return filename.replace(matchFileExtension, '.ts');
    case FileType.TEST:
      return filename.replace(matchFileExtension, '_test.ts');
    case FileType.HTML:
      return filename.replace(matchFileExtension, '.ng.html');
    case FileType.BUILD:
      return `${filename.replace(matchFileName, '')}/BUILD`;
    case FileType.HARNESS: {
      const fileNameWithoutPath = filename.replace(/.*\/(.*)/, '$1');
      const extensionlessFileName = fileNameWithoutPath.replace(
        matchFileExtension,
        '',
      );
      // remove ending forward slash
      path = path.replace(/\/$/, '');
      return `${path}/testing/${extensionlessFileName}_harness.ts`;
    }
    default:
      return convertTo satisfies never;
  }
}

if (import.meta.main) {
  const [filename, convertTo] = Deno.args;
  if (Deno.args.length < 2) {
    throw new Error(
      'Requires a filename argument and an argument of the type to conver to.',
    );
  }
  if (!Object.values<string>(FileType).includes(convertTo.toLowerCase())) {
    throw new Error(`Invalid FileType: ${convertTo.toString()}`);
  }
  console.log(main(filename, convertTo as FileType));
}

Deno.test('parse string to file type', () => {
  mod.assertEquals(
    main('my_component.scss', 'ts' as FileType),
    'my_component.ts',
  );
});

Deno.test('convert to test', () => {
  mod.assertEquals(
    main('my_component.ts', FileType.TEST),
    'my_component_test.ts',
  );
});

Deno.test('convert to html', () => {
  mod.assertEquals(
    main('my_component_test.ts', FileType.HTML),
    'my_component.ng.html',
  );
});

Deno.test('convert to scss', () => {
  mod.assertEquals(
    main('my_component.ng.html', FileType.SCSS),
    'my_component.scss',
  );
});

Deno.test('convert from scss to ts', () => {
  mod.assertEquals(main('my_component.scss', FileType.TS), 'my_component.ts');
});

Deno.test('convert from html to ts', () => {
  mod.assertEquals(
    main('this/that/my_component.ng.html', FileType.TS),
    'this/that/my_component.ts',
  );
});

Deno.test('convert to build', () => {
  mod.assertEquals(
    main('this/that/my_component.ts', FileType.BUILD),
    'this/that/BUILD',
  );
});

Deno.test('convert to harness', () => {
  mod.assertEquals(
    main('test/test.ts', FileType.HARNESS),
    'test/testing/test_harness.ts',
  );
});

Deno.test('convert from build to build', () => {
  const build = main('test/test.ts', FileType.BUILD);
  const buildBuild = main(build, FileType.BUILD);
  mod.assertEquals(buildBuild, 'test/BUILD');
});

Deno.test('convert from html to harness', () => {
  mod.assertEquals(
    main('this/that/my_component.ng.html', FileType.HARNESS),
    'this/that/testing/my_component_harness.ts',
  );
});

Deno.test('convert from ts to harness', () => {
  mod.assertEquals(
    main('this/that/my_component.ts', FileType.HARNESS),
    'this/that/testing/my_component_harness.ts',
  );
});

Deno.test('convert from harness to ts', () => {
  mod.assertEquals(
    main('this/that/testing/my_component_harness.ts', FileType.TS),
    'this/that/my_component.ts',
  );
});

Deno.test('convert from harness to test', () => {
  mod.assertEquals(
    main('this/that/testing/my_component_harness.ts', FileType.TEST),
    'this/that/my_component_test.ts',
  );
});

Deno.test('convert from harness to harness', () => {
  mod.assertEquals(
    main('this/that/testing/my_component_harness.ts', FileType.HARNESS),
    'this/that/testing/my_component_harness.ts',
  );
});

Deno.test('convert from harness to BUILD', () => {
  mod.assertEquals(
    main('this/that/testing/my_component_harness.ts', FileType.BUILD),
    'this/that/BUILD',
  );
});
