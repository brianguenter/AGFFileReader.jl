using Aqua
using JET

try
    Aqua.test_all(AGFFileReader)
catch
end

report_package(AGFFileReader)