import System.IO
import Data.List
import Data.Maybe
import Data.List.Split
import Graphics.EasyPlot
import qualified Data.Matrix as M
import qualified Data.Vector as V
import qualified Numeric.Matrix as K
import System.Environment

main = do
     args <- getArgs
     case args of
        ["-f", a, "-x", v, "-y", y]   -> regression a v y -- 1 argument
        otherwise          -> putStrLn "Usage : regression -f filename -x cols_of_explicative_var -y col_of_toExplaine_var \n Example : regression -f 'data.txt' -x '1 2 3' -y '0'"

regression fin xin yin = do
    file <- readFile fin
    let vs = map (\w -> read w :: Int) (splitOn " " xin)
    let yarg = read yin :: Int
    let list = stringToStrings (reverse(drop 1 (reverse(splitOn "\n" file))))
    let columns = map (\i -> (getColumn i list)) vs
    let x = M.transpose $ buildMatX $ columns
    let y = M.transpose $ buildMatY $ getColumn 0 list
    let yavg = (computeAverage (M.toList y))
    let b = buildMatB y x
    let yhat = buildYHat x b
    let r2 = computeR2 y yhat yavg
    let r2a = computeR2a r2 (M.nrows x) (M.ncols x)
    putStrLn "*********** Beta Matrix ***********"
    mapM_ (\(b,x) -> putStrLn ((show x) ++ " => " ++ (show b)) ) (zip (M.toList b) (0:vs))
    putStrLn "*********** Model Match ***********"
    putStr "Multiple R-squared : "; print r2
    putStr "Adjusted R-squared : "; print r2a
    --plot X11 $ [Data2D [Title "Reg", Style Points] [] (generatePlot (getColumn 0 list) (getColumn 2 list))]--, Data2D [Title "Model", Style Lines] [] (generatePlot (getColumn 2 list) (M.toList yhat))]
    --plot X11 $ [Data3D [Title "Reg", Style Points] [] (generate3DPlot (getColumn 2 list) (getColumn 3 list)), Data3D [Title "Model", Style Lines] [] (generate3DPlot (getColumn 2 list) (M.toList yhat))]

------------------------------------------------------------------------------------------------------------------------
--                                                PARSING FILE                                                        --
------------------------------------------------------------------------------------------------------------------------

stringToFloat :: [String] -> [Float]
stringToFloat s = map (\x ->  read x :: Float) s

stringToStrings :: [String] -> [[String]]
stringToStrings s = map (\y -> (filter (\x -> x/="") (splitOn " " y))) s

getColumn :: Int -> [[String]] -> [Float]
getColumn n s = stringToFloat (map (\x -> x!!n) s)

------------------------------------------------------------------------------------------------------------------------
--                                                 REGRESSION                                                         --
------------------------------------------------------------------------------------------------------------------------

buildMatX :: [[Float]] -> M.Matrix Float
buildMatX l = M.fromLists $ ([1.0 | _ <- [0..((length (l !! 0))-1)]]):l

buildMatY :: [Float] -> M.Matrix Float
buildMatY y = M.fromLists [y]

buildMatB :: M.Matrix Float -> M.Matrix Float -> M.Matrix Float
buildMatB y x = let xx = inverse ((M.transpose x) * x) in matB x y xx

matB :: M.Matrix Float -> M.Matrix Float -> Maybe(M.Matrix Float) -> M.Matrix Float
matB x y (Just(xx)) = ((xx) * (M.transpose x) * y)
matB x y Nothing = error "Matrix not inversible"

buildYHat :: M.Matrix Float -> M.Matrix Float -> M.Matrix Float
buildYHat x b = x * b

computeR2 :: M.Matrix Float -> M.Matrix Float -> Float -> Float
computeR2 y yhat yavg= (squareNorm(diffListWithValue (M.toList yhat) yavg))/(squareNorm(diffListWithValue (M.toList y) yavg))

computeR2a :: Float -> Int -> Int -> Float
computeR2a r2 n p = 1 - ((fromIntegral (n-1))/(fromIntegral(n-p))) * (1-r2)

------------------------------------------------------------------------------------------------------------------------
--                                              GRAPHIC EASYPLOT                                                      --
------------------------------------------------------------------------------------------------------------------------

generatePlot :: [Float] -> [Float] -> [(Float,Float)]
generatePlot xx yy = map (\i -> (xx !! i, yy !! i)) [i | i <- [0..((min (length xx) (length yy))-1)]]

generate3DPlot :: [Float] -> [Float] -> [(Float,Float,Float)]
generate3DPlot xx yy = map (\i -> (xx !! i, yy !! i, yy !! i)) [i | i <- [0..((min (length xx) (length yy))-1)]]

------------------------------------------------------------------------------------------------------------------------
--                                               HELPER STUFF                                                         --
------------------------------------------------------------------------------------------------------------------------

inverse :: M.Matrix Float -> Maybe(M.Matrix Float)
inverse m = let mat = (K.fromList (M.toLists m)) :: K.Matrix Float in inv (K.inv mat)

inv :: Maybe(K.Matrix Float) -> Maybe(M.Matrix Float)
inv (Just m) = Just(M.fromLists (K.toList m))
inv _ = Nothing

squareNorm :: [Float] -> Float
squareNorm v = foldr (+) 0.0 $ map (\x -> x*x) (v)

computeAverage :: [Float] -> Float
computeAverage l = (1.0/( fromIntegral (length l))) * (foldr (+) 0.0 l)

diffListWithValue :: [Float] -> Float -> [Float]
diffListWithValue l v = map (\x -> x-v) l
