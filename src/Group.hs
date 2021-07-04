
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}

module Group (module Group, Proxy(..)) where

-- import Crypto.Number.Basic
import Crypto.Number.ModArithmetic

import Formatting
import qualified Data.Text.Lazy as TL
import Data.Proxy (Proxy(..))

import Data.MemoTrie
import Data.Coerce ( coerce )
import Data.ByteString (ByteString)
import Data.ByteString.Base16 (encode)
import Crypto.Number.Serialize (i2osp)

import Test.QuickCheck ( chooseInteger, Arbitrary(arbitrary) )


-- 𝑞 = 2^256 − 189
q :: Integer
q = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFF43

-- p=2^{4096}-2^{3840} - 1 + 2^{256}(\lfloor2^{3584}\gamma\rfloor + \delta)$
-- where the value of
-- delta = 495448529856135475846147600290107731951815687842437876083937612367400355133042233301
p :: Integer
p = 0xFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_93C467E3_7DB0C7A4_D1BE3F81_0152CB56_A1CECC3A_F65CC019_0C03DF34_709AFFBD_8E4B59FA_03A9F0EE_D0649CCB_621057D1_1056AE91_32135A08_E43B4673_D74BAFEA_58DEB878_CC86D733_DBE7BF38_154B36CF_8A96D156_7899AAAE_0C09D4C8_B6B7B86F_D2A1EA1D_E62FF864_3EC7C271_82797722_5E6AC2F0_BD61C746_961542A3_CE3BEA5D_B54FE70E_63E6D09F_8FC28658_E80567A4_7CFDE60E_E741E5D8_5A7BD469_31CED822_03655949_64B83989_6FCAABCC_C9B31959_C083F22A_D3EE591C_32FAB2C7_448F2A05_7DB2DB49_EE52E018_2741E538_65F004CC_8E704B7C_5C40BF30_4C4D8C4F_13EDF604_7C555302_D2238D8C_E11DF242_4F1B66C2_C5D238D0_744DB679_AF289048_7031F9C0_AEA1C4BB_6FE9554E_E528FDF1_B05E5B25_6223B2F0_9215F371_9F9C7CCC_69DDF172_D0D62342_17FCC003_7F18B93E_F5389130_B7A661E5_C26E5421_4068BBCA_FEA32A67_818BD307_5AD1F5C7_E9CC3D17_37FB2817_1BAF84DB_B6612B78_81C1A48E_439CD03A_92BF5222_5A2B38E6_542E9F72_2BCE15A3_81B5753E_A8427633_81CCAE83_512B3051_1B32E5E8_D8036214_9AD030AA_BA5F3A57_98BB22AA_7EC1B6D0_F17903F4_E234EA60_34AA8597_3F79A93F_FB82A75C_47C03D43_D2F9CA02_D03199BA_CEDDD453_34DBC6B5_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF

pMinus1 :: Integer
pMinus1 = p - 1

-- r = p-1 / q
-- r = p-1 `div` q
r' :: Integer
r' = ((p - 1) * inverseCoprimes q p) `mod` p
r :: Integer
r = 0x00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001_00000000_00000000_00000000_00000000_00000000_00000000_00000000_000000BC_93C467E3_7DB0C7A4_D1BE3F81_0152CB56_A1CECC3A_F65CC019_0C03DF34_709B8AF6_A64C0CED_CF2D559D_A9D97F09_5C3076C6_86037619_148D2C86_C317102A_FA214803_1F04440A_C0FF0C9A_417A8921_2512E760_7B2501DA_A4D38A2C_1410C483_6149E2BD_B8C8260E_627C4646_963EFFE9_E16E495D_48BD215C_6D8EC9D1_667657A2_A1C8506F_2113FFAD_19A6B2BC_7C457604_56719183_309F874B_C9ACE570_FFDA877A_A2B23A2D_6F291C15_54CA2EB1_2F12CD00_9B8B8734_A64AD51E_B893BD89_1750B851_62241D90_8F0C9709_879758E7_E8233EAB_3BF2D6AB_53AFA32A_A153AD66_82E5A064_8897C9BE_18A0D50B_ECE030C3_432336AD_9163E33F_8E7DAF49_8F14BB28_52AFFA81_4841EB18_DD5F0E89_516D5577_76285C16_071D2111_94EE1C3F_34642036_AB886E3E_C28882CE_4003DEA3_35B4D935_BAE4B582_35B9FB2B_AB713C8F_705A1C7D_E4222020_9D6BBCAC_C4673186_01565272_E4A63E38_E2499754_AE493AC1_A8E83469_EEF35CA2_7C271BC7_92EEE211_56E617B9_22EA8F71_3C22CF28_2DC5D638_5BB12868_EB781278_FA0AB2A8_958FCCB5_FFE2E5C3_61FC1744_20122B01_63CA4A46_308C8C46_C91EA745_7C1AD0D6_9FD4A7F5_29FD4A7F_529FD4A7_F529FD4A_7F529FD4_A7F529FD_4A7F529F_D4A7F52A

rSpec :: Integer
rSpec =                                                                     0x00000000_00000000_00000000_00000000_00000000_00000000_00000000_000000BC_93C467E3_7DB0C7A4_D1BE3F81_0152CB56_A1CECC3A_F65CC019_0C03DF34_709B8AF6_A64C0CED_CF2D559D_A9D97F09_5C3076C6_86037619_148D2C86_C317102A_FA214803_1F04440A_C0FF0C9A_417A8921_2512E760_7B2501DA_A4D38A2C_1410C483_6149E2BD_B8C8260E_627C4646_963EFFE9_E16E495D_48BD215C_6D8EC9D1_667657A2_A1C8506F_2113FFAD_19A6B2BC_7C457604_56719183_309F874B_C9ACE570_FFDA877A_A2B23A2D_6F291C15_54CA2EB1_2F12CD00_9B8B8734_A64AD51E_B893BD89_1750B851_62241D90_8F0C9709_879758E7_E8233EAB_3BF2D6AB_53AFA32A_A153AD66_82E5A064_8897C9BE_18A0D50B_ECE030C3_432336AD_9163E33F_8E7DAF49_8F14BB28_52AFFA81_4841EB18_DD5F0E89_516D5577_76285C16_071D2111_94EE1C3F_34642036_AB886E3E_C28882CE_4003DEA3_35B4D935_BAE4B582_35B9FB2B_AB713C8F_705A1C7D_E4222020_9D6BBCAC_C4673186_01565272_E4A63E38_E2499754_AE493AC1_A8E83469_EEF35CA2_7C271BC7_92EEE211_56E617B9_22EA8F71_3C22CF28_2DC5D638_5BB12868_EB781278_FA0AB2A8_958FCCB5_FFE2E5C3_61FC1744_20122B01_63CA4A46_308C8C46_C91EA745_7C1AD0D6_9FD4A7F5_29FD4A7F_529FD4A7_F529FD4A_7F529FD4_A7F529FD_4A7F529F_D4A7F52A


-- g = g = 2^r mod p
g :: Integer
g = 0x037DE384_F98F6E03_8D2A3141_825B33D5_D45EC4CC_64CFD15E_750D6798_F5196CF2_A142CDF3_3F6EF853_840EC7D4_EC804794_CFB0CFB6_5363B256_6387B98E_E0E3DEF1_B706FA55_D5038FFB_4A62DCBB_93B1DDD8_D3B308DA_86D1C3A5_25EF356F_E5BB5931_4E656334_80B396E1_DD4B795F_78DE07D8_6B0E2A05_BE6AF78F_D7F736FC_BA6C032E_26E050AF_50A03C65_FA7B6C87_F4554CB5_7F3DABCB_AD8EB9D8_FDEBEEF5_8570669A_CC3EDA17_DBFC47B8_B3C39AA0_8B829B28_872E62B5_D1B13A98_F09D40AC_20C2AB74_A6750E7C_8750B514_1E221C41_F55BBA31_D8E41422_B64D2CBA_7AAA0E9F_D8785702_F6932825_BF45DE83_86D24900_742062C1_322B37C5_0AF18215_8090C35D_A9355E6C_F7F72DA3_9A2284FD_FB1918B2_A2A30E69_501FA234_2B728263_DF23F1DB_8355BDE1_EB276FB3_685F3716_72CEB313_FDAB069C_C9B11AB6_C59BCE62_BAAD96AA_C96B0DBE_0C7E71FC_B2255254_5A5D1CED_EEE01E4B_C0CDBDB7_6B6AD45F_09AF5E71_114A005F_93AD97B8_FE09274E_76C94B20_08926B38_CAEC94C9_5E96D628_F6BC8066_2BA06207_801328B2_C6A60526_BF7CD02D_9661385A_C3B1CBDB_50F759D0_E9F61C11_A07BF421_8F299BCB_29005200_76EBD2D9_5A3DEE96_D4809EF3_4ABEB83F_DBA8A12C_5CA82757_288A89C9_31CF564F_00E8A317_AE1E1D82_8E61369B_A0DDBADB_10C136F8_691101AD_82DC5477_5AB83538_40D99921_97D80A6E_94B38AC4_17CDDF40_B0C73ABF_03E8E0AA

gCalc :: Integer
gCalc = expFast 2 r' p

-- g' = 1/g mod p
g' :: Integer
g' = 0x9FDCD937_897686C7_AD874728_580795C8_00E24724_89C52D0E_94B6A0B1_A0AEDC59_4E031141_E4AFDB3E_9C0677EB_FB05FF9C_5492E772_901B60DE_02A70D74_06AA327C_0DAEB23A_5E377AF2_BACB531B_0908F258_8DF3BF97_42BD56E9_228CD28F_0519A1EA_D8A8235F_65124D74_A7E16867_238AD9D0_891BB362_89383F96_0AC4B81A_A18B853B_2A5BD682_36D21E2A_53723838_155DA318_3AB1CC34_53116828_107EE7A0_3D8EB1EB_9140D23B_2BF5196B_0BAB68C5_0D6928E4_396B3B1B_43D93026_5EDB7672_47EE1C72_45DD78FE_A086FB17_376CB33E_A7EA3A09_5FA4D9B7_31545C29_468B71E9_851218EE_7AAB5CB3_2CF26D77_2C147C48_CF0872B0_1FA0E727_2D18D1D1_670CEE3A_81B9A4DC_966F2F8E_6C1E9F86_740D7734_E9358864_FF64768C_0DB4D8B0_84360B57_3C3EC081_29F16A0D_65FE33DF_24C38F9A_11BB89AF_A7DCF908_187E50BE_4E585E8C_5CD78266_33AB67F7_6842B400_15EC01EC_70070FDC_2C063386_F54B321A_3965E59E_8ED7E77E_5D8874EE_FA22C6EF_37EC2B1C_3A04BA32_4D90AA0D_D4E08614_1C20FF48_0AAE2816_D4767B34_5799B86B_679094C1_6BEB2F7D_DA6E2F17_573DB2B5_68A8293F_3FF169E8_40214936_58094251_AD083F2D_720C156A_7E42C631_25A8E158_F7C3A07F_4C00A0B7_B77341A1_2E980180_F330EE02_DA6F7B6C_E0804D0D_D7FB1642_7295E01B_84996AF1_C85615B6_5C73FEBA_0E050717_537EA54A_C22E7234_1D25A809_C8F3F190_D65279C4
-- g' = 0x7C3760F7_C5286704_4BCDE2D4_759615F1_69B873FC_B465D96D_BE3CBFA5_8AA5EA94_31FE08F7_AAC4F859_8C240BE6_194B03E3_7F8A9DC7_8A255A82_BCE95959_FF52A6DE_66CF240A_50EDB093_4A987FD9_DA4AFD73_A38011BD_08F4AE43_573BDD50_FA6F70EE_EA067D6E_57D446DE_9351BEE5_0E6AD9A5_B9282967_F1CDA890_A21C79C4_3C398755_9F415CCC_4E9E71C2_E0D7E4AA_95C23510_891F0C98_0D2F67DD_14EF589A_356D9FE7_79AD2288_5923FAAC_1D334EDC_D64D1541_66446A96_879EEB61_D92ADB68_F7BFA1BA_F7F66B05_7409A10A_08297B79_31CDB706_21571E31_43335ED7_BF130C08_18A8F99D_60E71645_D399B793_11A28B7D_10D7F1D4_0918A836_1B937929_FB0E9B46_3F90E494_4E37EDBE_60F5F0BD_21F4737D_D526B4FF_7EFE36EE_5C8A0456_3B8F04CF_8E7A29EE_9742DA6E_27B7442C_5E9BD207_3F6274ED_FDD8CBEF_916F6433_19D8A385_D5D52587_25FC3FA8_ECCFE897_72C85A84_79754B8A_53A7F19E_EB64A1BE_23A767D2_898F9152_91D680BC_8778462E_2A6490EC_E23A5C99_F96F1677_3018050C_24D00A1C_720B05AC_6B74BDE8_1FDAF645_433A227E_75D13073_00DB62FA_259B711D_077923C1_23624482_C6CEEF6A_925FABA1_8E44A5C0_C02DF980_220B517B_C210655A_FD9A7C16_2A3FCFCE_FC12E7C9_1D625397_366B3570_596316E1_6DD24A1E_1DC330C0_F051A9C4_2E528E56_39750808_BEC8614C_CA123F27_A76F043A_2FD7864E_C61C4F66_3F896543_4A73E978
g'Calc :: Integer
g'Calc = inverseCoprimes g p

data ParamName = P | Q

newtype ElementMod (n :: ParamName) = ElementMod Integer
  deriving stock (Show, Eq)

instance Parameter p => Num (ElementMod p) where
  ElementMod a + ElementMod b = elementMod (a+b)
  ElementMod a * ElementMod b = elementMod (a*b)
  ElementMod a - ElementMod b = elementMod (a-b)
  fromInteger = elementMod
  negate (ElementMod n) = elementMod (negate n)
  abs n = n -- Assumed to always be non-negative
  signum (ElementMod n) = ElementMod (signum n)

instance Parameter p => Arbitrary (ElementMod p) where
  arbitrary = ElementMod <$> chooseInteger (0,param' @p Proxy - 1)

instance Parameter a => HasTrie (ElementMod a) where
  newtype (ElementMod a) :->: b = ElementModTrie (Integer :->: b)
  trie f = ElementModTrie (trie (coerce f))
  untrie (ElementModTrie iTrie) = \(ElementMod a) -> untrie iTrie a
  enumerate eTrie =
    map (\e -> (e,untrie eTrie e))
    $ coerce
    $ (1:)
    $ takeWhile (/= 1)
    $ iterate (\x -> (x*q) `mod` param' @a Proxy) g

class Parameter (a :: ParamName) where param' :: p a -> Integer

instance Parameter 'P where param' _ = p
instance Parameter 'Q where param' _ = q

type ElementModQ = ElementMod 'Q
type ElementModP = ElementMod 'P

{-# INLINE elementMod #-}
elementMod :: forall a. Parameter a => Integer -> ElementMod a
elementMod n = ElementMod (n `mod` param' @a Proxy)

zeroModP :: ElementModP
zeroModP = elementMod 0
oneModP  :: ElementModP
oneModP  = elementMod 1
twoModP  :: ElementModP
twoModP  = elementMod 2

zeroModQ :: ElementModQ
zeroModQ = elementMod 0
oneModQ  :: ElementModQ
oneModQ  = elementMod 1
twoModQ  :: ElementModQ
twoModQ  = elementMod 2

class AsInteger a where
  asInteger :: a -> Integer

instance AsInteger (ElementMod p) where
  {-# INLINE asInteger #-}
  asInteger (ElementMod i) = i

instance AsInteger Integer where
  {-# INLINE asInteger #-}
  asInteger i = i

data ElementModPOrQ
  = POrQ'P ElementModP
  | POrQ'Q ElementModQ

instance AsInteger ElementModPOrQ where
  {-# INLINE asInteger #-}
  asInteger (POrQ'P (ElementMod i)) = i
  asInteger (POrQ'Q (ElementMod i)) = i

data ElementModPOrQOrInt
  = POrQOrInt'P ElementModP
  | POrQOrInt'Q ElementModQ
  | POrQOrInt'Int Integer

instance AsInteger ElementModPOrQOrInt where
  {-# INLINE asInteger #-}
  asInteger (POrQOrInt'P (ElementMod i)) = i
  asInteger (POrQOrInt'Q (ElementMod i)) = i
  asInteger (POrQOrInt'Int           i)  = i

data ElementModQOrInt
  = QOrInt'Q ElementModQ
  | QOrInt'Int Integer

instance AsInteger ElementModQOrInt where
  {-# INLINE asInteger #-}
  asInteger (QOrInt'Q (ElementMod i)) = i
  asInteger (QOrInt'Int           i)  = i


data ElementModPOrInt
  = POrInt'P ElementModP
  | POrInt'Int Integer

instance AsInteger ElementModPOrInt where
  {-# INLINE asInteger #-}
  asInteger (POrInt'P (ElementMod i)) = i
  asInteger (POrInt'Int           i)  = i


powMod :: forall a b p. (AsInteger a, AsInteger b, Parameter p) => a -> b -> ElementMod p
powMod a b = ElementMod (expSafe (asInteger a) (asInteger b) (param' @p Proxy))

infixr 8 ^%
(^%) :: forall a b p. (AsInteger a, AsInteger b, Parameter p) => a -> b -> ElementMod p
(^%) = powMod

gPowP :: ElementModPOrQ -> ElementModP
gPowP = powMod (ElementMod @'P g)

{-# INLINE mult #-}
mult :: forall p a b. (Parameter p, AsInteger a, AsInteger b) => a -> b -> ElementMod p
mult a b = ElementMod ((asInteger a * asInteger b) `mod` param' @p Proxy)

multInv :: forall p a. (AsInteger a, Parameter p) => a -> ElementMod p
multInv e = ElementMod $ inverseCoprimes (asInteger e) (param' @p Proxy)

divP :: forall p. Parameter p => ElementMod p -> ElementMod p -> ElementMod p
divP a b = a `mult` multInv @p b

-- | Computes \( (P - n) \mod{P} \) for prime parameter \( P \)
negateN :: forall p. Parameter p => ElementMod p -> ElementMod p
negateN (ElementMod n) = ElementMod (param' @p Proxy - n)


isValidResidue :: ElementMod 'P -> Bool
isValidResidue self =
  let residue = powMod self q == oneModP
  in inBounds self && residue

inBounds :: forall p. Parameter p => ElementMod p -> Bool
inBounds (ElementMod self) = self >= 0 && self < param' @p Proxy

-- Formatting and bytestrings

toHex :: AsInteger a => a -> ByteString
toHex a = encode $ i2osp (asInteger a)

toHexBS :: ByteString -> ByteString
toHexBS = encode

toBytes :: AsInteger a => a -> ByteString
toBytes = i2osp . asInteger

asHex :: Integer -> String
asHex = formatToString ("0x" % splatWith (TL.chunksOf 8) (intercalated "_") (uppercased (lpadded 1024 '0' hex)))
