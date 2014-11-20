CREATE OR REPLACE FORCE VIEW APPS.XXPO_SECURITY_SUPPLY_V
(SECURITY_CLASS,USER_ID,PERSON_ID,PERSON_CLASS,VENDOR_CODE,VENDOR_SITE_CODE,WHSE_CODE,SEGMENT1,FREQUENT_WHSE_CODE)
AS
SELECT /*�ɓ������[�U*/
       '1'                        AS SECURITY_CLASS         -- �Z�L�����e�B�敪
      ,FU.USER_ID                 AS USER_ID                -- ���O�C�����[�UID
      ,PAP.PERSON_ID              AS PERSON_ID              -- �]�ƈ�ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- �]�ƈ��敪
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- �d����R�[�h
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- �d����T�C�g�R�[�h
      ,TO_CHAR(NULL)              AS WHSE_CODE              -- �q�ɃR�[�h
      ,TO_CHAR(NULL)              AS SEGMENT1               -- �ۊǑq�ɃR�[�h
      ,TO_CHAR(NULL)              AS FREQUENT_WHSE_CODE     -- ��v�ۊǑq�ɃR�[�h
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
WHERE  FU.EMPLOYEE_ID             = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3             = '1'     -- �����]�ƈ�
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
UNION
SELECT /*�p�b�J�[�E�O���H��*/
       '2'                        AS SECURITY_CLASS         -- �Z�L�����e�B�敪
      ,FU.USER_ID                 AS USER_ID                -- ���O�C�����[�UID
      ,PAP.PERSON_ID              AS PERSON_ID              -- �]�ƈ�ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- �]�ƈ��敪
      ,PAP.ATTRIBUTE4             AS VENDOR_CODE            -- �d����R�[�h
      ,PAP.ATTRIBUTE6             AS VENDOR_SITE_CODE       -- �d����T�C�g�R�[�h
      ,TO_CHAR(NULL)              AS WHSE_CODE              -- �q�ɃR�[�h
      ,TO_CHAR(NULL)              AS SEGMENT1               -- �ۊǑq�ɃR�[�h
      ,TO_CHAR(NULL)              AS FREQUENT_WHSE_CODE     -- ��v�ۊǑq�ɃR�[�h
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
WHERE  FU.EMPLOYEE_ID             = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3             = '2'     -- �O���]�ƈ�
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
UNION
SELECT /*���m�u��-�ʏ�*/
       '3'                        AS SECURITY_CLASS         -- �Z�L�����e�B�敪
      ,FU.USER_ID                 AS USER_ID                -- ���O�C�����[�UID
      ,PAP.PERSON_ID              AS PERSON_ID              -- �]�ƈ�ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- �]�ƈ��敪
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- �d����R�[�h
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- �d����T�C�g�R�[�h
      ,XILV.WHSE_CODE             AS WHSE_CODE              -- �q�ɃR�[�h
      ,XILV.SEGMENT1              AS SEGMENT1               -- �ۊǑq�ɃR�[�h
      ,XILV.FREQUENT_WHSE_CODE    AS FREQUENT_WHSE_CODE     -- ��v�ۊǑq�ɃR�[�h
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV
WHERE  FU.EMPLOYEE_ID                                   = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                   = '2'                      -- �O���]�ƈ�
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                   = XILV.PURCHASE_CODE       -- �d���悪������
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- �d����T�C�g��������
UNION
SELECT /*���m�u��-�֘A�q��*/
       '3'                        AS SECURITY_CLASS         -- �Z�L�����e�B�敪
      ,FU.USER_ID                 AS USER_ID                -- ���O�C�����[�UID
      ,PAP.PERSON_ID              AS PERSON_ID              -- �]�ƈ�ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- �]�ƈ��敪
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- �d����R�[�h
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- �d����T�C�g�R�[�h
      ,XILV2.WHSE_CODE            AS WHSE_CODE              -- �q�ɃR�[�h
      ,XILV2.SEGMENT1             AS SEGMENT1               -- �ۊǑq�ɃR�[�h
      ,XILV2.FREQUENT_WHSE_CODE   AS FREQUENT_WHSE_CODE     -- ��v�ۊǑq�ɃR�[�h
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV1
      ,XXCMN_ITEM_LOCATIONS_V    XILV2
WHERE  FU.EMPLOYEE_ID                                    = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                    = '2'                       -- �O���]�ƈ�
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                    = XILV1.PURCHASE_CODE       -- �d���悪������
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV1.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV1.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- �d����T�C�g��������
AND    XILV1.SEGMENT1                                    = XILV2.FREQUENT_WHSE_CODE  -- ��v�q�ɃR�[�h�ΏۂƂȂ��Ă���
AND    XILV2.SEGMENT1                                    <> XILV2.FREQUENT_WHSE_CODE -- �������g��e�Ƃ��Ă��Ȃ�����
UNION
SELECT /*�O���q�ɁE���ރ��[�J*/
       '4'                        AS SECURITY_CLASS         -- �Z�L�����e�B�敪
      ,FU.USER_ID                 AS USER_ID                -- ���O�C�����[�UID
      ,PAP.PERSON_ID              AS PERSON_ID              -- �]�ƈ�ID
      ,PAP.ATTRIBUTE3             AS PERSON_CLASS           -- �]�ƈ��敪
      ,TO_CHAR(NULL)              AS VENDOR_CODE            -- �d����R�[�h
      ,TO_CHAR(NULL)              AS VENDOR_SITE_CODE       -- �d����T�C�g�R�[�h
      ,XILV.WHSE_CODE             AS WHSE_CODE              -- �q�ɃR�[�h
      ,XILV.SEGMENT1              AS SEGMENT1               -- �ۊǑq�ɃR�[�h
      ,XILV.FREQUENT_WHSE_CODE    AS FREQUENT_WHSE_CODE     -- ��v�ۊǑq�ɃR�[�h
FROM   FND_USER                  FU
      ,PER_ALL_PEOPLE_F          PAP
      ,XXCMN_ITEM_LOCATIONS_V    XILV
WHERE  FU.EMPLOYEE_ID                                   = PAP.PERSON_ID
AND    PAP.ATTRIBUTE3                                   = '2'                      -- �O���]�ƈ�
AND    TRUNC(SYSDATE)  BETWEEN TRUNC(PAP.EFFECTIVE_START_DATE)
                           AND TRUNC(PAP.EFFECTIVE_END_DATE)
AND    PAP.ATTRIBUTE4                                   = XILV.PURCHASE_CODE       -- �d���悪������
AND    NVL(PAP.ATTRIBUTE6,NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ'))      = NVL(XILV.PURCHASE_SITE_CODE,'ZZZZZZZZZZ')  -- �d����T�C�g��������
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.SECURITY_CLASS         IS '�Z�L�����e�B�敪'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.USER_ID                IS '���O�C�����[�UID'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.PERSON_ID              IS '�]�ƈ�ID'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.PERSON_CLASS           IS '�]�ƈ��敪'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.VENDOR_CODE            IS '�d����R�[�h'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.VENDOR_SITE_CODE       IS '�d����T�C�g�R�[�h'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.WHSE_CODE              IS '�q�ɃR�[�h'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.SEGMENT1               IS '�ۊǑq�ɃR�[�h'
/
COMMENT ON COLUMN XXPO_SECURITY_SUPPLY_V.FREQUENT_WHSE_CODE     IS '��v�ۊǑq�ɃR�[�h'
/
COMMENT ON TABLE  XXPO_SECURITY_SUPPLY_V                        IS 'XXPO�L���x���Z�L�����e�BVIEW'
/
