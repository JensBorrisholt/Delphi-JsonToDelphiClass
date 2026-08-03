program EndToEndTest;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Winapi.Windows,
  Winapi.ShellAPI,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Console in 'System.Console.pas',
  Pkg.Json.Generator,
  Pkg.Json.GeneratorGUI.DemoProject,
  DelphiBuilderU in 'DelphiBuilderU.pas';

function DemoDataRoot: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\..\Demo Data'));
end;

var
  FullFileName, FileName: TFileName;
  s, OutputDirectory: String;
  DestinationClassName: string;
  Json: string;
  Generator: TJsonToDelphiGenerator;
  OutputBuffer: TStringlist;
  Sucess: boolean;

begin
  Console.ForegroundColor := TConsoleColor.White;

  try
    s := FormatDateTime('yyyymmdd-hhnnns', now);
    OutputBuffer := TStringlist.Create;
    try
      for FullFileName in TDirectory.GetFiles(DemoDataRoot, '*.json') do
      begin
        OutputDirectory := TPath.GetDocumentsPath +
          TPath.DirectorySeparatorChar + 'JsonToDelphiClass E2E Test\' +
          'Test Run ' + s + TPath.DirectorySeparatorChar;
        TDirectory.CreateDirectory(OutputDirectory);

        FileName := TPath.GetFileName(FullFileName).Replace('.json', '');
        DestinationClassName := string(FileName).Replace(#32, '');
        Console.Write('* Building E2E Test for %s ... ', [FileName]);

        Json := TFile.ReadAllText(FullFileName, TEncoding.UTF8);
        Generator := TJsonToDelphiGenerator.Create;
        try
          Generator.RootClassName := DestinationClassName;
          Generator.DestinationUnitName := DestinationClassName;
          Generator.Parse(Json);
          OutputDirectory := IncludeTrailingPathDelimiter(OutputDirectory) +
            DestinationClassName + TPath.DirectorySeparatorChar;
          TDemoProjectGenerator.Generate(OutputDirectory,
            Generator.DestinationUnitName, Generator.GeneratedRootClassName,
            Generator.Json, Generator.GenerateUnit, dpfVCL);
        finally
          Generator.Free;
        end;

        OutputBuffer.Clear;
        DelphiBuilder.CompileProject(OutputBuffer,
          OutputDirectory + 'VCL\Demo.dproj');

        FileName := OutputDirectory + 'Win32\Release\Demo.exe';
        Sucess := TFile.Exists(FileName);
        if Sucess then
        begin
          Console.ForegroundColor := TConsoleColor.Green;
          Console.WriteLine('Sucess!');
        end
        else
        begin
          Console.ForegroundColor := TConsoleColor.Red;
          Console.WriteLine('Failed!');
        end;

        if Sucess then
        begin
          Console.ForegroundColor := TConsoleColor.Blue;
          Console.Write('   Launching [%s] demo ... ',
            [TPath.GetFileName(FullFileName).Replace('.json', '')]);

          Sucess := ShellExecute(0, 'OPEN', Pchar(FileName), '',
            Pchar(TPath.GetDirectoryName(FileName)), SW_SHOWNORMAL) > 32;
          if Sucess then
          begin
            Console.ForegroundColor := TConsoleColor.Green;
            Console.WriteLine('Sucess!');
          end
          else
          begin
            Console.ForegroundColor := TConsoleColor.Red;
            Console.WriteLine('Failed!');
          end;
        end;

        Console.ForegroundColor := TConsoleColor.White;
        Console.WriteLine('');
      end;

      Console.ForegroundColor := TConsoleColor.White;
      Console.WriteLine('Press any key to continue ...');
      Console.ReadLine;
      OutputDirectory := TPath.GetDocumentsPath +
        TPath.DirectorySeparatorChar + 'JsonToDelphiClass E2E Test\' +
        'Test Run ' + s + TPath.DirectorySeparatorChar;

      ShellExecute(0, 'OPEN', Pchar(OutputDirectory), '', '', SW_SHOWNORMAL);
    finally
      OutputBuffer.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
