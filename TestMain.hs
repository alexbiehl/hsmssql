{-# OPTIONS_GHC -F -pgmF htfpp #-}
module Main where

import Test.Framework
import Database.Mssql.Tds
import Data.Binary.Put
import Data.Binary.Strict.Get
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as B
import qualified Data.Map as M
import Data.Char (ord)

test_parseInstances =
    let s = "\ENQ\179\NULServerName;sqlhost;InstanceName;SQLEXPRESS;" ++
            "IsClustered;No;Version;10.0.1600.22;tcp;49849;;" ++
            "ServerName;sqlhost;InstanceName;SQL2012;IsClustered;" ++
            "No;Version;11.0.2100.60;tcp;59958;;"
        bs = BS.pack $ map (fromIntegral . ord) s
        ref = [
            M.fromList [("InstanceName","SQL2012"),
                        ("IsClustered","No"),
                        ("ServerName","sqlhost"),
                        ("Version","11.0.2100.60"),
                        ("tcp","59958")],
            M.fromList [("InstanceName","SQLEXPRESS"),
                        ("IsClustered","No"),
                        ("ServerName","sqlhost"),
                        ("Version","10.0.1600.22"),
                        ("tcp","49849")]]
        decoded = parseInstances bs
    in
        assertEqual (Right ref) decoded

test_sendLogin =
    let login = (verTDS74,
                 0x1000,
                 0x01060100,
                 100,
                 0,
                 0xe0,
                 0,
                 0,
                 8,
                 -4 * 60,
                 0x204,
                 "subdev1",
                 "test",
                 "testpwd",
                 "appname",
                 "servername",
                 B.empty,
                 "library",
                 "en",
                 "database",
                 (MacAddress 0x12 0x34 0x56 0x78 0x90 0xab),
                 B.empty,
                 "filepath",
                 "")
        loginbuf = runPut $ serializeLogin login
        packet = runPut $ serializePacket packLogin7 loginbuf
        ref = [
            16, 1, 0, 222, 0, 0, 0, 0, 198+16, 0, 0, 0, 4, 0, 0, 116, 0, 16, 0, 0, 0, 1,
            6, 1, 100, 0, 0, 0, 0, 0, 0, 0, 224, 0, 0, 8, 16, 255, 255, 255, 4, 2, 0,
            0, 94, 0, 7, 0, 108, 0, 4, 0, 116, 0, 7, 0, 130, 0, 7, 0, 144, 0, 10, 0, 164,
            0, 0, 0, 164, 0, 7, 0, 178, 0, 2, 0, 182, 0, 8, 0, 18, 52, 86, 120, 144, 171,
            198, 0, 0, 0, 198, 0, 8, 0, 214, 0, 0, 0, 0, 0, 0, 0, 115, 0, 117, 0, 98,
            0, 100, 0, 101, 0, 118, 0, 49, 0, 116, 0, 101, 0, 115, 0, 116, 0, 226, 165,
            243, 165, 146, 165, 226, 165, 162, 165, 210, 165, 227, 165, 97, 0, 112,
            0, 112, 0, 110, 0, 97, 0, 109, 0, 101, 0, 115, 0, 101, 0, 114, 0, 118, 0,
            101, 0, 114, 0, 110, 0, 97, 0, 109, 0, 101, 0, 108, 0, 105, 0, 98, 0, 114,
            0, 97, 0, 114, 0, 121, 0, 101, 0, 110, 0, 100, 0, 97, 0, 116, 0, 97, 0, 98,
            0, 97, 0, 115, 0, 101, 0, 102, 0, 105, 0, 108, 0, 101, 0, 112, 0, 97, 0,
            116, 0, 104, 0]
    in
        assertEqual ref $ B.unpack packet

test_login = do
    login

main = htfMain htf_thisModulesTests
