/*************************************************************************
 * 
 * View  Name      : XXSKZ_�^���A�h�I��IFKI_��{_V
 * Description     : XXSKZ_�^���A�h�I��IFKI_��{_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------  -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------  -------------------------------------
 *  2012/11/27    1.0   SCSK M.Nagai ����쐬
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_�^���A�h�I��IFKI_��{_V
(
 �p�^�[���敪
,�p�^�[���敪��
,�^���Ǝ�
,�^���ƎҖ�
,�z��NO
,�����NO
,�x�������敪
,�x�������敪��
,�z���敪
,�z���敪��
,�����^��
,���P
,���Q
,�d�ʂP
,�d�ʂQ
,����
,������
,�ʍs��
,�s�b�L���O��
,���ڊ������z
,���v
,�쐬��
,�쐬��
,�ŏI�X�V��
,�ŏI�X�V��
,�ŏI�X�V���O�C��
)
AS
SELECT 
        XDI.pattern_flag                                  --�p�^�[���敪
       ,CASE XDI.pattern_flag                             --�p�^�[���敪��
            WHEN '1' THEN '�O���p'
            WHEN '2' THEN '�ɓ����Y�Ɨp'
        END                      pattern_name
       ,XDI.delivery_company_code                         --�^���Ǝ�
       ,XCV.party_name                                    --�^���ƎҖ�
       ,XDI.delivery_no                                   --�z��No
       ,XDI.invoice_no                                    --�����No
       ,XDI.p_b_classe                                    --�x�������敪
       ,FLV01.meaning                                     --�x�������敪��
       ,XDI.delivery_classe                               --�z���敪
       ,FLV02.meaning                                     --�z���敪��
       ,XDI.charged_amount                                --�����^��
       ,XDI.qty1                                          --���P
       ,XDI.qty2                                          --���Q
       ,XDI.delivery_weight1                              --�d�ʂP
       ,XDI.delivery_weight2                              --�d�ʂQ
       ,XDI.distance                                      --����
       ,XDI.many_rate                                     --������
       ,XDI.congestion_charge                             --�ʍs��
       ,XDI.picking_charge                                --�s�b�L���O��
       ,XDI.consolid_surcharge                            --���ڊ������z
       ,XDI.total_amount                                  --���v
       ,FU_CB.user_name         created_by_name           --CREATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XDI.creation_date, 'YYYY/MM/DD HH24:MI:SS')
                                creation_date             --�쐬����
       ,FU_LU.user_name         last_updated_by_name      --LAST_UPDATED_BY�̃��[�U�[��(���O�C�����̓��̓R�[�h)
       ,TO_CHAR( XDI.last_update_date, 'YYYY/MM/DD HH24:MI:SS')
                                last_update_date          --�X�V����
       ,FU_LL.user_name         last_update_login_name    --LAST_UPDATE_LOGIN�̃��[�U�[��(���O�C�����̓��̓R�[�h)
  FROM  xxwip_deliverys_if      XDI                       --�^���A�h�I���C���^�t�F�[�X
       ,xxskz_carriers_v        XCV                       --SKYLINK�p����VIEW �^���ƎҎ擾VIEW
       ,fnd_lookup_values       FLV01                     --�x�������敪���擾�p
       ,fnd_lookup_values       FLV02                     --�z���敪���擾�p
       ,fnd_user                FU_CB                     --���[�U�[�}�X�^(CREATED_BY���̎擾�p)
       ,fnd_user                FU_LU                     --���[�U�[�}�X�^(LAST_UPDATE_BY���̎擾�p)
       ,fnd_user                FU_LL                     --���[�U�[�}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
       ,fnd_logins              FL_LL                     --���O�C���}�X�^(LAST_UPDATE_LOGIN���̎擾�p)
 WHERE  XDI.delivery_company_code = XCV.freight_code(+)
    --�����f�[�^
   AND  XDI.p_b_classe            = '2'
    --�x�������敪���擾����
   AND  FLV01.language(+)         = 'JA'
   AND  FLV01.lookup_type(+)      = 'XXWIP_PAYCHARGE_TYPE'
   AND  FLV01.lookup_code(+)      = XDI.p_b_classe
   --�z���敪���擾����
   AND  FLV02.language(+)         = 'JA'
   AND  FLV02.lookup_type(+)      = 'XXCMN_SHIP_METHOD'
   AND  FLV02.lookup_code(+)      = XDI.delivery_classe
   --WHO�J�����擾
   AND  XDI.created_by            = FU_CB.user_id(+)
   AND  XDI.last_updated_by       = FU_LU.user_id(+)
   AND  XDI.last_update_login     = FL_LL.login_id(+)
   AND  FL_LL.user_id             = FU_LL.user_id(+)
/
COMMENT ON TABLE APPS.XXSKZ_�^���A�h�I��IFKI_��{_V                     IS 'SKYLINK�p�^���A�h�I��IF�i��{�jVIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�p�^�[���敪       IS '�p�^�[���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�p�^�[���敪��     IS '�p�^�[���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�^���Ǝ�           IS '�^���Ǝ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�^���ƎҖ�         IS '�^���ƎҖ�'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�z��NO             IS '�z��No'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�����NO           IS '�����No'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�x�������敪       IS '�x�������敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�x�������敪��     IS '�x�������敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�z���敪           IS '�z���敪'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�z���敪��         IS '�z���敪��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�����^��           IS '�����^��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.���P             IS '���P'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.���Q             IS '���Q'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�d�ʂP             IS '�d�ʂP'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�d�ʂQ             IS '�d�ʂQ'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.����               IS '����'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.������             IS '������'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�ʍs��             IS '�ʍs��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�s�b�L���O��       IS '�s�b�L���O��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.���ڊ������z       IS '���ڊ������z'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.���v               IS '���v'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�쐬��             IS '�쐬��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�ŏI�X�V��         IS '�ŏI�X�V��'
/
COMMENT ON COLUMN APPS.XXSKZ_�^���A�h�I��IFKI_��{_V.�ŏI�X�V���O�C��   IS '�ŏI�X�V���O�C��'
/
