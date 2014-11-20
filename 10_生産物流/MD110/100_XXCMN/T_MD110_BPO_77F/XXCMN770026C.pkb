CREATE OR REPLACE PACKAGE BODY xxcmn770026c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxcmn770026c(body)
 * Description      : �o�Ɏ��ѕ\
 * MD.050/070       : �����Y����(�o��)Issue1.0 (T_MD050_BPO_770)
 *                    �����Y����(�o��)Issue1.0 (T_MD070_BPO_77F)
 * Version          : 1.21
 *
 * Program List
 * -------------------------- ----------------------------------------------------------
 *  Name                       Description
 * -------------------------- ----------------------------------------------------------
 *  fnc_conv_xml              FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_initialize            PROCEDURE : �O����(F-1)
 *  prc_get_report_data       PROCEDURE : ���׃f�[�^�擾(F-1)
 *  prc_create_xml_data       PROCEDURE : �w�l�k�f�[�^�쐬(F-2)
 *  submain                   PROCEDURE : ���C�������v���V�[�W��
 *  main                      PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/04/11    1.0   Y.Itou           �V�K�쐬
 *  2008/05/16    1.1   T.Endou          �s�ID:77F-09,10�Ή�
 *                                       77F-09 �����N���p��YYYYM���͑Ή�
 *                                       77F-10 �S�������A�S���Җ��̍ő啶���������̏C��
 *  2008/05/16    1.2   T.Endou          ���ی����擾���@�̕ύX
 *  2008/06/16    1.3   T.Endou          ����敪
 *                                        �E�L��
 *                                        �E�U�֗L��_�o��
 *                                        �E���i�U�֗L��_�o��
 *                                       �ꍇ�́A�󒍃w�b�_�A�h�I��.�����T�C�gID�ŕR�t����
 *  2008/06/24    1.4   I.Higa           �f�[�^���������ڂł��O���o�͂���
 *  2008/06/25    1.5   T.Endou          ���蕶������o�͂��悤�Ƃ���ƁA�G���[�ƂȂ蒠�[���o��
 *                                       ����Ȃ����ۂւ̑Ή�
 *  2008/07/18    1.6   T.Ikehara        �o�͌����J�E���g�^�O�ǉ�
 *  2008/08/07    1.7   T.Endou          �Q�ƃr���[�̕ύX�uxxcmn_rcv_pay_mst_porc_rma_v�v��
 *                                                       �uxxcmn_rcv_pay_mst_porc_rma26_v�v
 *  2008/09/02    1.8   A.Shiina         �d�l�s����Q#T_S_475�Ή�
 *  2008/09/22    1.9   A.Shiina         �����ύX�v��#236�Ή�
 *  2008/10/15    1.10  A.Shiina         T_S_524�Ή�
 *  2008/10/24    1.11  N.Yoshida        T_S_524�Ή�(�đΉ�)
 *  2008/10/24    1.12  T.Yoshida        T_S_524�Ή�(�đΉ�2)
 *                                           �ύX�ӏ������̂��߁A�C���������c���Ă��Ȃ��̂ŁA
 *                                           �C���ӏ��m�F�̍ۂ͑OVer�ƍ�����r���邱��
 *  2008/11/12    1.13  N.Yoshida        �ڍs�f�[�^���ؕs��Ή�(�����폜)
 *  2008/12/02    1.14  A.Shiina         �{��#207�Ή�
 *  2008/12/08    1.15  N.Yoshida        �{�ԏ�Q���l���킹�Ή�(�󒍃w�b�_�̍ŐV�t���O��ǉ�)
 *  2008/12/13    1.16  A.Shiina         �{��#428�Ή�
 *  2008/12/13    1.17  N.Yoshida        �{��#428�Ή�(�đΉ�)
 *  2008/12/16    1.18  A.Shiina         �{��#749�Ή�
 *  2008/12/16    1.19  A.Shiina         �{��#754�Ή� -- �Ή��폜
 *  2008/12/17    1.20  A.Shiina         �{��#428�Ή�(PT�Ή�)
 *  2008/12/18    1.21  A.Shiina         �{��#799�Ή�
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0' ;
  gv_status_warn   CONSTANT VARCHAR2(1) := '1' ;
  gv_status_error  CONSTANT VARCHAR2(1) := '2' ;
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ' ;
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
  -- ======================================================
  -- ���[�U�[�錾��
  -- ======================================================
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                 CONSTANT VARCHAR2(20) := 'XXCMN770026C' ; -- �p�b�P�[�W��
  gv_print_name               CONSTANT VARCHAR2(20) := '�o�Ɏ��ѕ\' ;   -- ���[��
--
  ------------------------------
  -- �W�v�O���[�v
  ------------------------------
  gc_party_sum_desc           CONSTANT VARCHAR2(16) := '�o�א�v';
  gc_whse_sum_desc            CONSTANT VARCHAR2(16) := '�q�Ɍv';
  gc_article_div_sum_name     CONSTANT VARCHAR2(16) := '�i�ڋ敪���v';
  gc_result_post_sum_name     CONSTANT VARCHAR2(16) := '���ѕ����v';
--
  ------------------------------
  -- �i�ڃJ�e�S���֘A
  ------------------------------
  gc_cat_set_name_prod_div    CONSTANT VARCHAR2(20) := '���i�敪' ;
  gc_cat_set_name_item_div    CONSTANT VARCHAR2(20) := '�i�ڋ敪' ;
  gc_cat_set_name_crowd       CONSTANT VARCHAR2(20) := '�Q�R�[�h' ;
  gc_cat_set_name_acnt_crowd  CONSTANT VARCHAR2(20) := '�o�����p�Q�R�[�h' ;
--
  ------------------------------
  -- ���̓p�����[�^
  ------------------------------
  gc_param_all_code           CONSTANT VARCHAR2(20) := 'ALL' ;
  gc_param_all_name           CONSTANT VARCHAR2(20) := '�W�v����' ;
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  gc_application              CONSTANT VARCHAR2(5)  := 'XXCMN' ;       -- �A�v���P�[�V����
  gc_crowd_type_3             CONSTANT VARCHAR2(1)  := '3' ;           -- �S��ʁF�S�R�[�h
  gc_crowd_type_4             CONSTANT VARCHAR2(1)  := '4' ;           -- �S��ʁF�o���S�R�[�h
--
  ------------------------------
  -- ���ڕҏW�֘A
  ------------------------------
  gc_char_ym_format           CONSTANT VARCHAR2(30) := 'YYYYMMDD' ;
  gc_char_m_format            CONSTANT VARCHAR2(30) := 'YYYYMM' ;
  gc_char_dt_format           CONSTANT VARCHAR2(30) := 'YYYY/MM/DD HH24:MI:SS';
--
  ------------------------------
  -- �N�C�b�N�R�[�h�E�^�C�v��
  ------------------------------
  gc_xxcmn_new_acc_div        CONSTANT VARCHAR2(30) := 'XXCMN_NEW_ACCOUNT_DIV';
--
  -- �����敪
  gc_cost_ac                  CONSTANT VARCHAR2(1) := '0'; --���ی���
  gc_cost_st                  CONSTANT VARCHAR2(1) := '1'; --�W������
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data  IS RECORD (
    proc_from                 VARCHAR2(6)       -- 01 : �����N��FROM
   ,proc_to                   VARCHAR2(6)       -- 02 : �����N��TO
   ,rcv_pay_div               VARCHAR2(5)       -- 03 : �󕥋敪
   ,rcv_pay_div_name          VARCHAR2(20)      --    : �󕥋敪��
   ,prod_div                  VARCHAR2(1)       -- 04 : ���i�敪
   ,prod_div_name             VARCHAR2(20)      --    : ���i�敪��
   ,item_div                  VARCHAR2(1)       -- 05 : �i�ڋ敪
   ,item_div_name             VARCHAR2(20)      --    : �i�ڋ敪��
   ,result_post               VARCHAR2(4)       -- 06 : ���ѕ���
   ,result_post_name          VARCHAR2(20)      --    : ���ѕ�����
   ,whse_code                 VARCHAR2(4)       -- 07 : �q�ɃR�[�h
   ,whse_name                 VARCHAR2(20)      --    : �q�ɖ�
   ,party_code                VARCHAR2(4)       -- 08 : �o�א�R�[�h
   ,party_name                VARCHAR2(20)      --    : �o�א於
   ,crowd_type                VARCHAR2(1)       -- 09 : �S���
   ,crowd_code                VARCHAR2(4)       -- 10 : �S�R�[�h
   ,acnt_crowd_code           VARCHAR2(4)       -- 11 : �o���Q�R�[�h
   ,output_type               VARCHAR2(20)      -- 12 : �o�͎��
  ) ;
--
  -- �o�׎��ѕ\�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_data_type_dtl  IS RECORD (
-- 2008/09/22 v1.9 UPDATE START
/*
    group1_code               VARCHAR2(5)                         -- [�W�v1]�R�[�h
   ,group2_code               VARCHAR2(5)                         -- [�W�v2]�R�[�h
   ,group3_code               VARCHAR2(5)                         -- [�W�v3]�R�[�h
   ,group4_code               VARCHAR2(5)                         -- [�W�v4]�R�[�h
   ,group5_code               VARCHAR2(4)                         -- [�W�v5]�W�v�S�R�[�h
   ,req_item_code             ic_item_mst_b.item_no%TYPE          -- �o�וi�ڃR�[�h
   ,item_code                 ic_item_mst_b.item_no%TYPE          -- �i�ڃR�[�h
   ,req_item_name             xxcmn_item_mst_b.item_name%TYPE     -- �o�וi�ږ���
   ,item_name                 xxcmn_item_mst_b.item_name%TYPE     -- �i�ږ���
*/
    group1_code               VARCHAR2(240)                       -- [�W�v1]�R�[�h
   ,group2_code               VARCHAR2(40)                        -- [�W�v2]�R�[�h
   ,group3_code               VARCHAR2(30)                        -- [�W�v3]�R�[�h
   ,group4_code               VARCHAR2(30)                        -- [�W�v4]�R�[�h
   ,group5_code               VARCHAR2(40)                        -- [�W�v5]�W�v�S�R�[�h
-- 2008/12/13 v1.16 ADD START
   ,group1_name               VARCHAR2(240)                       -- [�W�v1]����
   ,group2_name               VARCHAR2(240)                       -- [�W�v2]����
   ,group3_name               VARCHAR2(240)                       -- [�W�v3]����
   ,group4_name               VARCHAR2(240)                       -- [�W�v4]����
-- 2008/12/13 v1.16 ADD END
   ,req_item_code             VARCHAR2(240)                        -- �o�וi�ڃR�[�h
   ,item_code                 xxcmn_lot_each_item_v.item_code%TYPE        -- �i�ڃR�[�h
   ,req_item_name             xxcmn_item_mst2_v.item_short_name%TYPE      -- �o�וi�ږ���
   ,item_name                 xxcmn_lot_each_item_v.item_short_name%TYPE  -- �i�ږ���
-- 2008/09/22 v1.9 UPDATE END
   ,trans_um                  ic_tran_pnd.trans_um%TYPE           -- ����P��
   ,trans_qty                 NUMBER                              -- �������
   ,actual_price              NUMBER                              -- ���ۋ��z
   ,stnd_price                NUMBER                              -- �W�����z
   ,price                     NUMBER                              -- �L�����z
   ,tax                       NUMBER                              -- �����
  ) ;
  TYPE tab_data_type_dtl IS TABLE OF rec_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gn_user_id                    fnd_user.user_id%TYPE DEFAULT FND_GLOBAL.USER_ID; -- ���[�U�[�h�c
  ------------------------------
  -- �r�p�k�����p
  ------------------------------
  gv_user_dept                  xxcmn_locations_all.location_short_name%TYPE;     -- �S������
  gv_user_name                  per_all_people_f.per_information18%TYPE;          -- �S����
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gv_report_id                  VARCHAR2(15) ;              -- ���[ID
  gd_exec_date                  DATE ;                      -- ���{��
--
  gt_main_data                  tab_data_type_dtl ;         -- �擾���R�[�h�\
  gt_xml_data_table             XML_DATA ;                  -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                    NUMBER DEFAULT 0 ;          -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
-- 2008/12/13 v1.16 DELETE START
/*
  gv_gr1_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�P����
  gv_gr2_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�Q����
  gv_gr3_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�R����
  gv_gr4_sum_desc               VARCHAR2(16) DEFAULT NULL ; -- �W�v�S����
--
*/
-- 2008/12/13 v1.16 DELETE END
  ------------------------------
  -- ����敪
  ------------------------------
  gv_charge                     xxcmn_lookup_values_v.lookup_code%TYPE; -- �L��;
  gv_trans_charge               xxcmn_lookup_values_v.lookup_code%TYPE; -- �U�֗L��_�o��';
  gv_item_charge                xxcmn_lookup_values_v.lookup_code%TYPE; -- ���i�U�֗L��_�o��';
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt         EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt             EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt      EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml (
    iv_name              IN        VARCHAR2   --   �^�O�l�[��
   ,iv_value             IN        VARCHAR2   --   �^�O�f�[�^
   ,ic_type              IN        CHAR       --   �^�O�^�C�v
  ) RETURN VARCHAR2
  IS
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'fnc_conv_xml' ;   -- �v���O������
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���ϐ� ***
    lv_convert_data         VARCHAR2(2000) ;
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>' ;
    END IF ;
--
    RETURN(lv_convert_data) ;
--
  END fnc_conv_xml ;
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : �O����(F-1)
   ***********************************************************************************/
  PROCEDURE prc_initialize (
    ir_param             IN OUT NOCOPY rec_param_data -- 01.���̓p�����[�^�Q
   ,ov_errbuf               OUT    VARCHAR2           -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode              OUT    VARCHAR2           -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg               OUT    VARCHAR2           -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_initialize' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���萔 ***
    -- ����敪
    lc_charge             CONSTANT VARCHAR2(30) := '�L��';
    lc_trans_charge       CONSTANT VARCHAR2(30) := '�U�֗L��_�o��';
    lc_item_charge        CONSTANT VARCHAR2(30) := '���i�U�֗L��_�o��';
    lc_xxcmn_dealings_div CONSTANT VARCHAR2(30) := 'XXCMN_DEALINGS_DIV';
--
    -- *** ���[�J���ϐ� ***
    -- *** ���[�J���E��O���� ***
    get_value_expt        EXCEPTION ;     -- �l�擾�G���[
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ====================================================
    -- �S���������擾
    -- ====================================================
    gv_user_dept := xxcmn_common_pkg.get_user_dept( gn_user_id ) ;
--
    -- ====================================================
    -- �S���Җ��擾
    -- ====================================================
    gv_user_name := xxcmn_common_pkg.get_user_name( gn_user_id ) ;
--
    -- ====================================================
    -- ����敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlvv.meaning, 1, 20)
        INTO   ir_param.rcv_pay_div_name
        FROM   xxcmn_lookup_values_v xlvv
        WHERE  xlvv.lookup_type  = gc_xxcmn_new_acc_div
        AND    xlvv.lookup_code  = ir_param.rcv_pay_div
        AND    ROWNUM            = 1
        ;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- ���i�敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.prod_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.prod_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_prod_div
        AND    xcv.segment1          = ir_param.prod_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �i�ڋ敪���擾
    -- ====================================================
    -- �l�I���̏ꍇ�A���̂��擾����
    IF ( ir_param.item_div IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xcv.description, 1, 20)
        INTO   ir_param.item_div_name
        FROM   xxcmn_categories_v xcv
        WHERE  xcv.category_set_name = gc_cat_set_name_item_div
        AND    xcv.segment1          = ir_param.item_div
        AND    ROWNUM                = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- ���ѕ������擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�����v��ݒ�
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post = gc_param_all_code )
    THEN
      ir_param.result_post_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.result_post IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( xlv.location_short_name, 1, 20)
        INTO   ir_param.result_post_name
        FROM   xxcmn_locations_v xlv
        WHERE  xlv.location_code = ir_param.result_post
        AND    ROWNUM            = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �q�ɖ��擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�����v��ݒ�
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code = gc_param_all_code )
    THEN
      ir_param.whse_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.whse_code IS NOT NULL ) THEN
      BEGIN
        SELECT SUBSTRB( iwm.whse_name, 1, 20)
        INTO   ir_param.whse_name
        FROM   ic_whse_mst iwm
        WHERE  iwm.whse_code = ir_param.whse_code
        AND    ROWNUM        = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    END IF;
--
    -- ====================================================
    -- �o�א於�擾
    -- ====================================================
    -- [ALL]�̏ꍇ�A���̂ɌŒ�l�u�W�v�Ȃ��v��ݒ�
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code = gc_param_all_code )
    THEN
      ir_param.party_name := gc_param_all_name;
--
    -- �l�I���̏ꍇ�A���̂��擾����
    ELSIF ( ir_param.party_code IS NOT NULL ) THEN
-- 2008/12/16 v1.18 ADD START
     -- �o�ׂ̏ꍇ
     IF (ir_param.rcv_pay_div IN ('102', '101', '112')) THEN
-- 2008/12/16 v1.18 ADD END
      BEGIN
        SELECT SUBSTRB( xpv.party_short_name, 1, 20)
        INTO   ir_param.party_name
        FROM   xxcmn_parties_v xpv
        WHERE  xpv.party_number = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
-- 2008/12/16 v1.18 ADD START
     -- �L���̏ꍇ
     ELSIF (ir_param.rcv_pay_div IN ('103', '105', '108')) THEN
      BEGIN
        SELECT SUBSTRB( xvv.vendor_short_name, 1, 20)
        INTO   ir_param.party_name
        FROM   xxcmn_vendors_v xvv
        WHERE  xvv.segment1 = ir_param.party_code
        AND    ROWNUM           = 1;
      EXCEPTION
        -- �f�[�^�Ȃ�
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
--
     END IF;
--
-- 2008/12/16 v1.18 ADD END
    END IF;
--
    -- ====================================================
    -- �����敪�R�[�h�擾�i�L���j
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- �����敪�R�[�h�擾�i�U�֗L��_�o�ׁj
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_trans_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_trans_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
    -- ====================================================
    -- �����敪�R�[�h�擾�i���i�U�֗L��_�o�ׁj
    -- ====================================================
    BEGIN
      SELECT xlvv.lookup_code
      INTO   gv_item_charge
      FROM   xxcmn_lookup_values_v xlvv
      WHERE  xlvv.lookup_type = lc_xxcmn_dealings_div
      AND    xlvv.meaning     = lc_item_charge
      AND    ROWNUM           = 1;
    EXCEPTION
      -- �f�[�^�Ȃ�
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
--
  EXCEPTION
    --*** �l�擾�G���[��O ***
    WHEN get_value_expt THEN
--
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := lv_retcode ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_initialize ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���׃f�[�^�擾(F-1)
   ***********************************************************************************/
  PROCEDURE prc_get_report_data (
    ir_param      IN  rec_param_data            -- 01.���̓p�����[�^�Q
   ,ot_data_rec   OUT NOCOPY tab_data_type_dtl  -- 02.�擾���R�[�h�Q
   ,ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_get_report_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���E�萔 ***
-- 2008/10/24 v1.10 ADD START
    cn_prod_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_PROD_CLASS'));
    cn_item_class_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ITEM_CLASS'));
    cn_crowd_code_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_CROWD_CODE'));
    cn_acnt_crowd_id     CONSTANT NUMBER := TO_NUMBER(FND_PROFILE.VALUE('XXCMN_ITEM_CATEGORY_ACNT_CROWD_CODE'));
-- 2008/10/24 v1.10 ADD END
--
    -- *** ���[�J���E�ϐ� ***
-- 2008/10/24 v1.10 UPDATE START
    /*lv_select               VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_omso            VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_porc            VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_where                VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_group_by             VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_order_by             VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_sql                  VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_porc_charge     VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_omso_charge     VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_where_no_charge      VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_where_charge         VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_porc_where      VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k
    lv_from_omso_where      VARCHAR2(32000) ;     -- �f�[�^�擾�p�r�p�k*/
    lv_where                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_where2               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_where3               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_main_start            VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_common                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_main_end              VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group1                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group1_2              VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group2                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group3                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group3_2              VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group4                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group5                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group5_2              VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group6                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group7                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group7_2              VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_group8                VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po102_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po102_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po102_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po102_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po102_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po102               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po102               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po101_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po101_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po101_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po101_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po101_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po101               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po101               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po112_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po112_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po112_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po112_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po112_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po112               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po112               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x5_1_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x5_2_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x5_3_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x5_4_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x5_6_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po103x5             VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po103x5             VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x124_1_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x124_2_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x124_3_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x124_4_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po103x124_6_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po103x124           VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po103x124           VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po105_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po105_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po105_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po105_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po105_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po105               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po105               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po108_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po108_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po108_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po108_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_po108_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_po108               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_po108               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
--
    lv_select_g1_om102_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om102_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om102_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om102_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om102_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om102               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om102               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om101_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om101_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om101_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om101_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om101_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om101               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om101               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om112_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om112_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om112_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om112_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om112_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om112               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om112               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x5_1_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x5_2_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x5_3_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x5_4_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x5_6_hint     VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om103x5             VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om103x5             VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x124_1_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x124_2_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x124_3_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x124_4_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om103x124_6_hint   VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om103x124           VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om103x124           VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om105_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om105_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om105_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om105_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om105_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om105               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om105               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om108_1_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om108_2_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om108_3_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om108_4_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_g1_om108_6_hint       VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_1_om108               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
    lv_select_2_om108               VARCHAR2(32767) ;     -- �f�[�^�擾�p�r�p�k
--
    lt_lkup_code            fnd_lookup_values.lookup_code%TYPE;
    --lv_crowd_c_name         VARCHAR2(20) ;        -- �S�R�[�h�J������(���o�����p)
--
    -- *** ���[�J���E�J�[�\�� ***
    TYPE   ref_cursor IS REF CURSOR ;
    lc_ref ref_cursor ;
--
    get_cur01    ref_cursor;
-- 2008/10/24 v1.10 UPDATE END
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
-- 2008/10/24 v1.10 UPDATE START
-- 2008/10/24 v1.10 ADD START  
    SELECT flv.lookup_code
    INTO   lt_lkup_code
    FROM   xxcmn_lookup_values_v flv
    WHERE  flv.lookup_type = 'XXCMN_CONSUMPTION_TAX_RATE'
    AND    ROWNUM          = 1;
--
    lv_select_main_start :=
       ' SELECT'
    || '  mst.group1_code AS group1_code' -- [�W�v1]�R�[�h
    || ' ,mst.group2_code AS group2_code' -- [�W�v2]�R�[�h
    || ' ,mst.group3_code AS group3_code' -- [�W�v3]�R�[�h
    || ' ,mst.group4_code AS group4_code' -- [�W�v4]�R�[�h
    || ' ,mst.group5_code AS group5_code' -- [�W�v5]�R�[�h
-- 2008/12/13 v1.16 ADD START
    || ' ,mst.group1_name AS group1_name' -- [�W�v1]����
    || ' ,mst.group2_name AS group2_name' -- [�W�v2]����
    || ' ,mst.group3_name AS group3_name' -- [�W�v3]����
    || ' ,mst.group4_name AS group4_name' -- [�W�v4]����
-- 2008/12/13 v1.16 ADD END
    || ' ,mst.request_item_code AS request_item_code' -- �o�וi�ڃR�[�h
    || ' ,mst.item_code AS item_code' -- �i�ڃR�[�h
    || ' ,MAX(mst.request_item_name) AS request_item_name' -- �o�וi�ږ���
    || ' ,MAX(mst.item_name) AS item_name' -- ����P��
    || ' ,MAX(mst.trans_um) AS trans_um' -- �������
    || ' ,SUM(mst.trans_qty) AS trans_qty' -- �������
    || ' ,SUM(mst.actual_price) AS actual_price' -- ���ۋ��z
    || ' ,SUM(mst.stnd_price) AS stnd_price' -- �W�����z
    || ' ,SUM(mst.price) AS price' -- �L�����z
    || ' ,SUM(mst.price * DECODE( NVL(mst.tax,0),0,0,(mst.tax/100) ) )'
    || ' AS tax' -- ����ŗ� 
    || ' FROM ('
       ;
-- 
 -- ����SELECT
    lv_select_common :=
       ' xola.request_item_code AS request_item_code'
    || ' ,ximb2.item_short_name AS request_item_name'
    || ' ,iimb.item_no AS item_code'
    || ' ,ximb.item_short_name AS item_name'
    || ' ,itp.trans_um AS trans_um'
    || ' ,itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)'
    || ' AS trans_qty' -- ������� 
-- 2008/12/02 v1.14 UPDATE START
/*
    || ' ,(' 
    || ' ROUND((CASE iimb2.attribute15'
    || ' WHEN ''1'' THEN xsupv.stnd_unit_price' 
    || ' ELSE DECODE('
    || ' iimb2.lot_ctl' 
    || ' ,1,(SELECT DECODE('
    || ' SUM(NVL(xlc.trans_qty,0))' 
    || ' ,0,0' 
    || ' ,SUM(xlc.trans_qty * xlc.unit_ploce) / SUM(NVL(xlc.trans_qty,0)))'
    || ' FROM xxcmn_lot_cost xlc'
    || ' WHERE xlc.item_id = iimb2.item_id),xsupv.stnd_unit_price)' 
    || ' END) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))'
    || ' ) AS actual_price' -- ���ۋ��z
*/
    || ' ,(' 
    || ' ROUND((CASE iimb2.attribute15'
    || '          WHEN ''1'' THEN xsupv.stnd_unit_price' 
    || '          ELSE DECODE(iimb2.lot_ctl' 
    || '                     ,1,NVL(xlc.unit_ploce, 0)' 
    || '                     ,xsupv.stnd_unit_price)' 
    || '        END) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))' 
    || ' ) AS actual_price' -- ���ۋ��z
-- 2008/12/02 v1.14 UPDATE END
    || ' ,ROUND(xsupv.stnd_unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))'
    || ' ) AS stnd_price' -- �W�����z
-- 2008/12/02 v1.14 UPDATE START
/*
    || ' ,(CASE iimb.lot_ctl'
    || ' WHEN 0 THEN ROUND((xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))))'
    || ' ELSE ROUND(((SELECT DECODE('
    || ' SUM(NVL(xlc.trans_qty,0))' 
    || ' ,0,0' 
    || ' ,SUM(xlc.trans_qty * xlc.unit_ploce) / SUM(NVL(xlc.trans_qty,0)))'
    || ' FROM xxcmn_lot_cost xlc'
    || ' WHERE xlc.item_id = itp.item_id ) * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)))'
    || ' )' 
    || ' END) AS price' -- �L�����z
*/
-- 2008/12/18 v1.21 UPDATE START
--    || ' ,xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div)) AS price' -- �L�����z
    || ' ,ROUND(xola.unit_price * (itp.trans_qty * TO_NUMBER(xrpm.rcv_pay_div))) AS price' -- �L�����z
-- 2008/12/18 v1.21 UPDATE END
-- 2008/12/02 v1.14 UPDATE END
    || ' ,TO_NUMBER(''' || lt_lkup_code    || ''') AS tax' 
    ;
-- 
 -- ����SELECT group1 
    lv_select_group1 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
    || ' ,itp.whse_code AS group3_code' -- �q��
--    || ' ,xpv.party_number AS group4_code' -- �o�א�
    || ' ,hca.account_number AS group4_code' -- �o�א�
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group3_name' -- �q�ɖ���
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group4_name' -- �o�א於��
    || ' ,xp.party_short_name    AS group4_name' -- �o�א於��
-- 2008/12/17 v1.20 UPDATE END
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 2008/12/13 v1.16 ADD START
 -- ����SELECT group1_2
    lv_select_group1_2 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
    || ' ,itp.whse_code AS group3_code' -- �q��
    || ' ,pv.segment1 AS group4_code' -- �x����
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group3_name' -- �q�ɖ���
    || ' ,pv.vendor_name          AS group4_name' -- �x���於��
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- ����SELECT group2 
    lv_select_group2 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
    || ' ,itp.whse_code AS group3_code' -- �q��
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group3_name' -- �q�ɖ���
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- ����SELECT group3 
    lv_select_group3 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
--    || ' ,xpv.party_number AS group3_code' -- �o�א�
    || ' ,hca.account_number AS group3_code' -- �o�א�
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group3_name' -- �o�א於��
    || ' ,xp.party_short_name    AS group3_name' -- �o�א於��
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
-- 2008/12/13 v1.16 ADD START
 -- ����SELECT group3_2
    lv_select_group3_2 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
    || ' ,pv.segment1 AS group3_code' -- �x����
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
    || ' ,pv.vendor_name          AS group3_name' -- �x���於��
    || ' ,NULL                    AS group4_name' -- NULL
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- ����SELECT group4 
    lv_select_group4 :=
       ' ,ooha.attribute11 AS group1_code' -- ���ѕ��� 
    || ' ,mcb2.segment1 AS group2_code' -- �i�ڋ敪
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,xla.location_short_name  AS group1_name' -- ���ѕ�������
    || ' ,NULL                    AS group1_name' -- ���ѕ�������
--    || ' ,mct.description         AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- ����SELECT group5 
    lv_select_group5 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
    || ' ,itp.whse_code AS group2_code' -- �q��
--    || ' ,xpv.party_number AS group3_code' -- �o�א�
    || ' ,hca.account_number AS group3_code' -- �o�א�
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �q�ɖ���
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group3_name' -- �o�א於��
    || ' ,xp.party_short_name    AS group3_name' -- �o�א於��
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 2008/12/13 v1.16 ADD START
 -- ����SELECT group5_2
    lv_select_group5_2 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
    || ' ,itp.whse_code AS group2_code' -- �q��
    || ' ,pv.segment1 AS group3_code' -- �x����
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �q�ɖ���
    || ' ,pv.vendor_name          AS group3_name' -- �x���於��
    || ' ,NULL                    AS group4_name' -- NULL
    ;
-- 2008/12/13 v1.16 ADD END
-- 
 -- ����SELECT group6 
    lv_select_group6 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
    || ' ,itp.whse_code AS group2_code' -- �q��
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- �q�ɖ���
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- ����SELECT group7 
    lv_select_group7 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
--    || ' ,xpv.party_number AS group2_code' -- �o�א�
    || ' ,hca.account_number AS group2_code' -- �o�א�
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
-- 2008/12/17 v1.20 UPDATE START
--    || ' ,xpv.party_short_name    AS group2_name' -- �o�א於��
    || ' ,xp.party_short_name    AS group2_name' -- �o�א於��
-- 2008/12/17 v1.20 UPDATE END
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
-- 2008/12/13 v1.16 ADD START
 -- ����SELECT group7_2
    lv_select_group7_2 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
    || ' ,pv.segment1 AS group2_code' -- �x����
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
    || ' ,pv.vendor_name          AS group2_name' -- �x���於��
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
    ;
--
-- 2008/12/13 v1.16 ADD END
 -- ����SELECT group8 
    lv_select_group8 :=
       ' ,mcb2.segment1 AS group1_code' -- �i�ڋ敪 
    || ' ,NULL AS group2_code' -- NULL
    || ' ,NULL AS group3_code' -- NULL
    || ' ,NULL AS group4_code' -- NULL
    || ' ,mcb3.segment1 AS group5_code' -- �S�R�[�h or �o���S�R�[�h 
-- 2008/12/13 v1.16 ADD START
--    || ' ,mct.description         AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group1_name' -- �i�ڋ敪����
    || ' ,NULL                    AS group2_name' -- NULL
    || ' ,NULL                    AS group3_name' -- NULL
    || ' ,NULL                    AS group4_name' -- NULL
-- 2008/12/13 v1.16 ADD END
    ;
-- 
    lv_select_main_end :=
       ' ) mst' 
    || ' GROUP BY '
    || ' mst.group1_code' -- [�W�v1]�R�[�h
    || ' ,mst.group2_code' -- [�W�v2]�R�[�h
    || ' ,mst.group3_code' -- [�W�v3]�R�[�h
    || ' ,mst.group4_code' -- [�W�v4]�R�[�h
    || ' ,mst.group5_code' -- [�W�v5]�R�[�h
-- 2008/12/13 v1.16 ADD START
    || ' ,mst.group1_name' -- [�W�v1]����
    || ' ,mst.group2_name' -- [�W�v2]����
    || ' ,mst.group3_name' -- [�W�v3]����
    || ' ,mst.group4_name' -- [�W�v4]����
-- 2008/12/13 v1.16 ADD END
    || ' ,mst.request_item_code' -- �o�וi�ڃR�[�h
    || ' ,mst.item_code' -- �i�ڃR�[�h
    || ' ORDER BY '
    || ' mst.group1_code' -- [�W�v1]�R�[�h
    || ' ,mst.group2_code' -- [�W�v2]�R�[�h
    || ' ,mst.group3_code' -- [�W�v3]�R�[�h
    || ' ,mst.group4_code' -- [�W�v4]�R�[�h
    || ' ,mst.group5_code' -- [�W�v5]�R�[�h
    || ' ,mst.request_item_code' -- �o�וi�ڃR�[�h
    || ' ,mst.item_code' -- �i�ڃR�[�h
    ;
-- 
 --===============================================================
 -- GROUP1�A2�A4�A6�A7
 --===============================================================
-- 
 -- PORC_102
 -- �p�^�[��:1
    lv_select_1_po102 :=
       ' FROM ' 
    || '  ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''102''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.category_id   = mcb2.category_id'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND xl.start_date_active  <= TRUNC(SYSDATE)'
--    || ' AND xl.end_date_active    >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
--
-- 
 -- PORC_101
 -- �p�^�[��:1
    lv_select_1_po101 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''101''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_112
 -- �p�^�[��:1
    lv_select_1_po112 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' ||cn_item_class_id    || '''' 
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''112''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.category_id   = mcb2.category_id'
-- 2008/12/17 v1.20 DELETe START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETe END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_103_5
 -- �p�^�[��:1
    lv_select_1_po103x5 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id' 
    || ' AND rsl.oe_order_line_id    = xola.line_id' 
    || ' AND xoha.header_id          = ooha.header_id' 
    || ' AND xola.order_header_id    = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_103_124
 -- �p�^�[��:1
    lv_select_1_po103x124 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND rsl.oe_order_header_id  = xola.header_id'
    || ' AND rsl.oe_order_line_id    = xola.line_id'
    || ' AND xoha.header_id          = ooha.header_id'
    || ' AND xola.order_header_id    = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin IS NULL' 
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_105
 -- �p�^�[��:1
    lv_select_1_po105 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5'''
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id   = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''105''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- PORC_108
 -- �p�^�[��:1
    lv_select_1_po108 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,rcv_shipment_lines rsl'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,gmi_item_categories gic5'
    || ' ,mtl_categories_b mcb5'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''PORC''' -- �����^�C�v(PORC)
    || ' AND itp.completed_ind = 1' -- �����t���O
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND mcb1.segment1 = ''1''' 
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 = ''5''' 
    || ' AND gic5.item_id = itp.item_id' 
    || ' AND gic5.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic5.category_id = mcb5.category_id' 
    || ' AND mcb5.segment1 = ''2''' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND rsl.shipment_header_id = itp.doc_id' 
    || ' AND rsl.line_num = itp.doc_line' 
--    || ' AND oola.header_id = rsl.oe_order_header_id' 
--    || ' AND oola.line_id = rsl.oe_order_line_id' 
--    || ' AND ooha.header_id = rsl.oe_order_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = rsl.oe_order_line_id' 
    || ' AND ooha.header_id  = rsl.oe_order_header_id' 
    || ' AND xoha.header_id  = rsl.oe_order_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id    = rsl.oe_order_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''PORC'''
    || ' AND xrpm.source_document_code = ''RMA'''
    || ' AND xrpm.dealings_div = ''108''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_102
 -- �p�^�[��:1
    lv_select_1_om102 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id  = xoha.header_id' 
    || ' AND wdd.source_line_id    = xola.line_id' 
    || ' AND xoha.header_id        = ooha.header_id' 
    || ' AND xola.order_header_id  = xoha.order_header_id' 
    || ' AND xola.request_item_code = xola.shipping_item_code' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xp.party_id       = hps.party_id' 
    || ' AND hca.party_id      = hps.party_id' 

-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''102''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_101
 -- �p�^�[��:1
    lv_select_1_om101 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'

-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id   = xoha.header_id'
    || ' AND wdd.source_line_id     = xola.line_id'
    || ' AND xoha.header_id         = ooha.header_id'
    || ' AND xola.order_header_id   = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''101''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 v1.20 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 v1.20 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_112
 -- �p�^�[��:1
    lv_select_1_om112 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' ,xxcmn_party_sites2_v xpsv' -- �p�[�e�B�T�C�g���View2 
-- 2008/12/13 v1.17 N.Yoshida mod start
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
--    || ' ,xxcmn_cust_accounts2_v xpv' -- �ڋq���View2 
    || ' ,xxcmn_parties xpv' -- �ڋq���View2 
*/
    || ' ,hz_party_sites hps'
    || ' ,xxcmn_parties xp'
-- 2008/12/17 v1.20 UPDATE END
    || ' ,hz_cust_accounts hca'
-- 2008/12/13 v1.17 N.Yoshida mod start
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''04''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/17 v1.20 UPDATE START
/*
    || ' AND xpsv.party_site_id = xoha.result_deliver_to_id' 
    || ' AND xpsv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpsv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xpsv.party_id = xpv.party_id' 
    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
*/
    || ' AND hps.party_site_id     = xoha.result_deliver_to_id' 
    || ' AND xp.party_id           = hps.party_id' 
    || ' AND xp.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xp.end_date_active   >= TRUNC(itp.trans_date)' 
    || ' AND hca.party_id          = hps.party_id' 
-- 2008/12/17 v1.20 UPDATE END
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''112''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
-- 2008/12/17 DELETE START
--    || ' AND hca.party_id =  xpv.party_id'
-- 2008/12/17 DELETE END
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_103_5
 -- �p�^�[��:1
    lv_select_1_om103x5 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id = xoha.header_id'
    || ' AND wdd.source_line_id = xola.line_id'
    || ' AND xoha.header_id = ooha.header_id'
    || ' AND xola.order_header_id = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin = mcb2.segment1' 
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_103_124
 -- �p�^�[��:1
    lv_select_1_om103x124 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = itp.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = itp.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 IN (''1'',''2'',''4'')' 
    || ' AND gic3.item_id = itp.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND wdd.source_header_id = xoha.header_id'
    || ' AND wdd.source_line_id = xola.line_id'
    || ' AND xoha.header_id = ooha.header_id'
    || ' AND xola.order_header_id = xoha.order_header_id'
    || ' AND xola.request_item_code = xola.shipping_item_code'
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = itp.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''103''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND (xrpm.item_div_origin = mcb2.segment1' 
    || ' OR xrpm.item_div_origin IS NULL)' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
    || ' AND xrpm.item_div_origin IS NULL' 
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_105
 -- �p�^�[��:1
    lv_select_1_om105 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 IN (''1'',''2'',''4'')' 
    || ' AND xrpm.item_div_ahead = mcb2.segment1' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''105''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
-- 
 -- OMSO_108
 -- �p�^�[��:1
    lv_select_1_om108 :=
       ' FROM ' 
    || ' ic_tran_pnd itp'
    || ' ,wsh_delivery_details wdd'
--    || ' ,oe_order_lines_all oola'
    || ' ,oe_order_headers_all ooha'
    || ' ,oe_transaction_types_all otta'
    || ' ,xxwsh_order_headers_all xoha'
    || ' ,xxwsh_order_lines_all xola'
    || ' ,gmi_item_categories gic1'
    || ' ,mtl_categories_b mcb1'
    || ' ,gmi_item_categories gic2'
    || ' ,mtl_categories_b mcb2'
    || ' ,gmi_item_categories gic3'
    || ' ,mtl_categories_b mcb3'
    || ' ,gmi_item_categories gic4'
    || ' ,mtl_categories_b mcb4'
    || ' ,gmi_item_categories gic5'
    || ' ,mtl_categories_b mcb5'
    || ' ,ic_item_mst_b iimb'
    || ' ,xxcmn_item_mst_b ximb'
    || ' ,ic_lots_mst ilm'
    || ' ,xxcmn_lot_cost xlc'
    || ' ,ic_item_mst_b iimb2'
    || ' ,xxcmn_item_mst_b ximb2'
--    || ' ,ic_item_mst_b iimb3'
    || ' ,xxcmn_stnd_unit_price_v xsupv' -- �W���������View 
    || ' ,po_vendor_sites_all pvsa' -- �d����T�C�g�}�X�^ 
    || ' ,po_vendors pv' -- �d����}�X�^ 
-- 2008/12/13 v1.17 DELETE START
--    || ' ,xxcmn_parties2_v xpv' -- �p�[�e�B���View2 
-- 2008/12/13 v1.17 DELETE END
    || ' ,xxcmn_rcv_pay_mst xrpm'
-- 2008/12/13 v1.16 ADD START
--    || ' ,hr_locations_all  hla '
--    || ' ,xxcmn_locations_all xla '
--    || ' ,mtl_categories_tl mct '
-- 2008/12/13 v1.16 ADD END
    || ' WHERE itp.doc_type = ''OMSO''' 
    || ' AND itp.completed_ind = 1' 
--    || ' AND itp.trans_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
--    || ' AND itp.trans_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.latest_external_flag = ''Y'''
    || ' AND xoha.arrival_date >= FND_DATE.STRING_TO_DATE(''' || ir_param.proc_from    || ''',''yyyymm'')'
    || ' AND xoha.arrival_date < ADD_MONTHS( FND_DATE.STRING_TO_DATE(''' || ir_param.proc_to    || ''',''yyyymm''),1)'
    || ' AND xoha.req_status = ''08''' 
    || ' AND gic1.item_id = iimb2.item_id' 
    || ' AND gic1.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic1.category_id = mcb1.category_id' 
    || ' AND mcb1.segment1 = ''' || ir_param.prod_div    || ''''
    || ' AND mcb1.segment1 = ''1''' 
    || ' AND gic2.item_id = iimb2.item_id' 
    || ' AND gic2.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic2.category_id = mcb2.category_id' 
    || ' AND mcb2.segment1 = ''5''' 
    || ' AND gic3.item_id = iimb2.item_id' 
    || ' AND gic3.category_set_id = ''' || cn_crowd_code_id    || ''''
    || ' AND gic3.category_id = mcb3.category_id' 
    || ' AND gic4.item_id = itp.item_id' 
    || ' AND gic4.category_set_id = ''' || cn_item_class_id    || ''''
    || ' AND gic4.category_id = mcb4.category_id' 
    || ' AND mcb4.segment1 = ''5''' 
    || ' AND gic5.item_id = itp.item_id' 
    || ' AND gic5.category_set_id = ''' || cn_prod_class_id    || ''''
    || ' AND gic5.category_id = mcb5.category_id' 
    || ' AND mcb5.segment1 = ''2''' 
    || ' AND ilm.item_id = itp.item_id' 
    || ' AND ilm.lot_id = itp.lot_id' 
    || ' AND iimb.item_id = ilm.item_id' 
    || ' AND xlc.item_id(+) = ilm.item_id' 
    || ' AND xlc.lot_id (+) = ilm.lot_id'
    || ' AND ximb.item_id = iimb.item_id' 
    || ' AND ximb.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND wdd.delivery_detail_id = itp.line_detail_id' 
--    || ' AND oola.org_id = wdd.org_id' 
--    || ' AND oola.header_id = wdd.source_header_id' 
--    || ' AND oola.line_id = wdd.source_line_id' 
--    || ' AND ooha.header_id = wdd.source_header_id' 
    || ' AND otta.transaction_type_id = ooha.order_type_id' 
    || ' AND ((otta.attribute4 <> ''2'')' 
    || ' OR (otta.attribute4 IS NULL))' 
--    || ' AND xoha.header_id = ooha.header_id' 
--    || ' AND xola.line_id = wdd.source_line_id'
    || ' AND xoha.header_id = wdd.source_header_id' 
    || ' AND xoha.header_id = ooha.header_id' 
    || ' AND xola.order_header_id = xoha.order_header_id' 
    || ' AND xola.line_id  = wdd.source_line_id' 
    || ' AND iimb2.item_no = xola.request_item_code' 
    || ' AND ximb2.item_id = iimb2.item_id' 
    || ' AND ximb2.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND ximb2.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND xsupv.item_id = iimb2.item_id' 
    || ' AND xsupv.start_date_active <= TRUNC(itp.trans_date)' 
    || ' AND xsupv.end_date_active >= TRUNC(itp.trans_date)' 
    || ' AND pvsa.vendor_site_id = xoha.vendor_site_id' 
    || ' AND pv.vendor_id = pvsa.vendor_id' 
-- 2008/12/13 v1.16 UPDATE START
--    || ' AND pv.customer_num = xpv.account_number' 
--    || ' AND xoha.customer_id = xpv.party_id' 
-- 2008/12/13 v1.16 UPDATE END
-- 2008/12/13 v1.17 DELETE START
--    || ' AND xpv.start_date_active <= TRUNC(itp.trans_date)' 
--    || ' AND xpv.end_date_active >= TRUNC(itp.trans_date)' 
-- 2008/12/13 v1.17 DELETE START
    || ' AND xrpm.doc_type = itp.doc_type' 
    || ' AND xrpm.doc_type = ''OMSO'''
    || ' AND xrpm.dealings_div = ''108''' 
    || ' AND xrpm.shipment_provision_div = otta.attribute1' 
    || ' AND xrpm.ship_prov_rcv_pay_category = otta.attribute11' 
    || ' AND xrpm.break_col_06 IS NOT NULL'
-- 2008/12/13 v1.16 ADD START
--    || ' AND hla.location_code  = ooha.attribute11'
--    || ' AND hla.location_id    = xla.location_id'
--    || ' AND mct.category_id   = mcb2.category_id'
--    || ' AND hla.inactive_date  IS NULL'
--    || ' AND xla.start_date_active <= TRUNC(SYSDATE)'
--    || ' AND xla.end_date_active   >= TRUNC(SYSDATE)'
--    || ' AND mct.source_lang   = ''JA'''
--    || ' AND mct.language      = ''JA'''
-- 2008/12/13 v1.16 ADD END
    ;
---------------------------
--  �p�^�[���ʃq���g��
---------------------------
 --===============================================================
 -- GROUP1 PTN01
 --===============================================================
--
 -- PORC_102
    lv_select_g1_po102_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
-- 2008/12/17 v1.20 UPDTE START
--       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 2008/12/17 v1.20 UPDTE END
--
 -- PORC_101
    lv_select_g1_po101_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
--
 -- PORC_112
    lv_select_g1_po112_1_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha ooha otta xola iimb2 gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola iimb2 gic1 mcb1 gic2 mcb2) */';
-- 2008/12/17 v1.20 UPDATE END
--
 -- PORC_103_5
    lv_select_g1_po103x5_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_1_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_1_hint :=
       --' SELECT /*+ leading(itp gic4 mcb4 gic5 mcb5 rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp gic4 mcb4 gic5 mcb5 rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta xrpm) */';
-- 2008/12/17 v1.20 UPDATE END
-- 
 -- OMSO_101
    lv_select_g1_om101_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_1_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
-- 2008/12/17 v1.20 UPDATE START
--       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
       ' SELECT /*+ leading (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) use_nl (xoha ooha otta xola wdd itp gic1 mcb1 gic2 mcb2) */';
-- 2008/12/17 v1.20 UPDATE END
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_1_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_1_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_1_hint :=
       --' SELECT /*+ leading(itp gic4 mcb4 gic5 mcb5 wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp gic4 mcb4 gic5 mcb5 wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';

 --===============================================================
 -- GROUP1 PTN02
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
--
 -- PORC_101
    lv_select_g1_po101_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
--
 -- PORC_112
    lv_select_g1_po112_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_2_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp rsl xola iimb3 gic2 mcb2 gic1 gic4 mcb4 gic5 mcb5 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_2_hint :=
       --' SELECT /*+ leading(itp gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_2_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp wdd xola iimb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
 --===============================================================
 -- GROUP1 PTN03
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */'; 
--
 -- PORC_101
    lv_select_g1_po101_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */'; 
--
 -- PORC_112
    lv_select_g1_po112_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola gic3 mcb3 iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 rsl ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola rsl itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_3_hint :=
       --' SELECT /*+ leading(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp rsl xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */'; 
       --' SELECT /*+ leading (itp rsl xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (itp rsl xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_3_hint :=
       --' SELECT /*+ leading(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta) use_nl(itp gic3 mcb3 gic2 mcb2 gic1 mcb1 wdd ooha otta)*/';
       ' SELECT /*+ leading (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) use_nl (xoha xola wdd itp gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta xrpm) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_3_hint :=
       --' SELECT /*+ leading(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) use_nl(itp wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1 gic4 mcb4 gic5 mcb5 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
--
 --===============================================================
 -- GROUP1 PTN04
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */'; 
--
 -- PORC_101
    lv_select_g1_po101_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */'; 
--
 -- PORC_112
    lv_select_g1_po112_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_4_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic4 mcb4 gic5 mcb5 xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic4 mcb4 gic5 mcb5 xola iimb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_4_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
--
 --===============================================================
 -- GROUP1 PTN05
 --===============================================================
 -- GROUP1 PTN03�Ɠ��l
--
 --===============================================================
 -- GROUP1 PTN06
 --===============================================================
-- 
 -- PORC_102
    lv_select_g1_po102_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */'; 
--
 -- PORC_101
    lv_select_g1_po101_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */'; 
--
 -- PORC_112
    lv_select_g1_po112_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
--
 -- PORC_103_5
    lv_select_g1_po103x5_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */'; 
-- 
 -- PORC_103_124
    lv_select_g1_po103x124_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       ' SELECT /*+ leading (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola rsl ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */'; 
-- 
 -- PORC_105
    lv_select_g1_po105_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- PORC_108
    lv_select_g1_po108_6_hint :=
       --' SELECT /*+ leading(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(itp rsl ooha otta xrpm xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) */'; 
       --' SELECT /*+ leading (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl (itp rsl ooha otta xrpm xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) use_nl (xoha xola iimb2 gic3 mcb3 gic2 mcb2 gic1 mcb1 ooha otta) */'; 
-- 
 -- OMSO_102
    lv_select_g1_om102_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_101
    lv_select_g1_om101_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_112
    lv_select_g1_om112_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_103_5
    lv_select_g1_om103x5_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_103_124
    lv_select_g1_om103x124_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd itp gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) use_nl (xoha xola wdd ooha otta xrpm itp gic3 mcb3 gic1 mcb1 gic2 mcb2) */';
-- 
 -- OMSO_105
    lv_select_g1_om105_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
-- 
 -- OMSO_108
    lv_select_g1_om108_6_hint :=
       --' SELECT /*+ leading(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1) use_nl(xrpm otta ooha wdd xola iimb3 gic3 mcb3 gic2 mcb2 gic1 mcb1)*/';
       ' SELECT /*+ leading (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) use_nl (xoha xola iimb2 gic3 mcb3 gic1 mcb1 gic2 mcb2 ooha otta xrpm wdd itp) */';
--
 --===============================================================
--
 -- GROUP1 PTN07
 --===============================================================
 -- GROUP1 PTN04�Ɠ��l
-- 
 --===============================================================
--
 -- GROUP1 PTN08
 --===============================================================
 -- GROUP1 PTN06�Ɠ��l
-- 
-- 2008/10/24 v1.10 ADD START
--
    -- ���̓p�����[�^�[�̐ݒ�
    -- �u�󕥋敪�v�𒊏o�����ɐݒ�
    IF  ( ir_param.rcv_pay_div IS NOT NULL ) THEN
      lv_where := lv_where
        || ' AND xrpm.new_div_account = ''' || ir_param.rcv_pay_div || ''''
        ;
    END IF;
--
    -- �u�q�ɃR�[�h�v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.whse_code IS NOT NULL )
    AND ( ir_param.whse_code != gc_param_all_code )
    THEN
      lv_where := lv_where
        || ' AND itp.whse_code = '''        || ir_param.whse_code || ''''
        ;
    END IF;
--
    -- �u���ѕ����v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.result_post IS NOT NULL )
    AND ( ir_param.result_post != gc_param_all_code )
    THEN
      lv_where := lv_where
--        || ' AND xrpm.result_post = '''     || ir_param.result_post || ''''
        || ' AND ooha.attribute11 = '''     || ir_param.result_post || ''''
        ;
    END IF;
--
    -- �u�S��ʁv���u3:�S�R�[�h�v�ŁA���A�u�S�R�[�h�v�����͂���Ă���ꍇ�A���o�����ɐݒ�
    IF    ( ir_param.crowd_type = gc_crowd_type_3 ) THEN
      lv_where := lv_where
        || ' AND gic3.category_set_id = '''      || cn_crowd_code_id || ''''
        ;
--
      IF ( ir_param.crowd_code IS NOT NULL ) THEN
        lv_where := lv_where
          || ' AND mcb3.segment1 = '''      || ir_param.crowd_code || ''''
          ;
      END IF;
    -- �u�S��ʁv���u4:�o���S�R�[�h�v�ŁA���A�u�o���S�R�[�h�v�����͂���Ă���ꍇ�A���o�����ɐݒ�
    ELSIF ( ir_param.crowd_type =  gc_crowd_type_4 ) THEN
      lv_where := lv_where
        || ' AND gic3.category_set_id = ''' || cn_acnt_crowd_id || ''''
        ;
      IF ( ir_param.acnt_crowd_code IS NOT NULL ) THEN
        lv_where := lv_where
          || ' AND mcb3.segment1 = ''' || ir_param.acnt_crowd_code || ''''
          ;
      END IF;
    END IF;
--
    -- �u�i�ڋ敪�v���ʑI������Ă���ꍇ�A���o�����ɐݒ�
    IF  ( ir_param.item_div IS NOT NULL ) THEN
      lv_where := lv_where
--        || ' AND mcb2.item_div = '''        || ir_param.item_div || ''''
        || ' AND mcb2.segment1 = '''        || ir_param.item_div || ''''
        ;
    END IF;
--
    -- �u�o�א�R�[�h�v���ʑI������Ă���ꍇ(*ALL������)�A���o�����ɐݒ�
    IF  ( ir_param.party_code IS NOT NULL )
    AND ( ir_param.party_code != gc_param_all_code )
    THEN
-- 2008/12/13 v1.17 N.yoshida mod start
      lv_where2 := lv_where
        || ' AND xoha.customer_code = '''    || ir_param.party_code || ''''
               ;
      lv_where3 := lv_where
        || ' AND xoha.vendor_code   = '''    || ir_param.party_code || ''''
               ;
    ELSE
      lv_where2 := lv_where;
      lv_where3 := lv_where;
-- 2008/12/13 v1.17 N.yoshida mod end
    END IF;
--
    -- �W�v�p�^�[���P�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q�ɁA4.�o�א�)
    IF  ( ir_param.result_post IS NULL )
    AND ( ir_param.whse_code   IS NULL )
    AND ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP1
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP1
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group1
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group1_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���Q�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�q��)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP2
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP2
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���R�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪�A3.�o�א�)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP3
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP3
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group3
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group3_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���S�ݒ� (�W�v�F1.���ѕ����A2.�i�ڋ敪)
    ELSIF ( ir_param.result_post IS NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP4
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP4
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group4
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���T�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q�ɁA3.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP5
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP5
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group5
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group5_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���U�ݒ� (�W�v�F1.�i�ڋ敪�A2.�q��)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP6
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP6
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group6
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���V�ݒ� (�W�v�F1.�i�ڋ敪�A2.�o�א�)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NULL )
    THEN
--
      --GROUP7
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP7
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group7
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group7_2
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;
--
    -- �W�v�p�^�[���W�ݒ� (�W�v�F1.�i�ڋ敪)
    ELSIF ( ir_param.result_post IS NOT NULL )
    AND   ( ir_param.whse_code   IS NOT NULL )
    AND   ( ir_param.party_code  IS NOT NULL )
    THEN
--
      --GROUP8
      --PTN01
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      IF  (  ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_1_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN02
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_2_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN03
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN04
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN05
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          =  NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_3_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN06
      --�i�ڋ敪          =  NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NOT NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NOT NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN07
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  =  NULL
      --�󕥋敪          <> NULL
      ELSIF (ir_param.item_div    IS NOT NULL ) 
      AND (((ir_param.crowd_type = gc_crowd_type_3) AND ( ir_param.crowd_code       IS NULL )) OR
          (( ir_param.crowd_type = gc_crowd_type_4) AND ( ir_param.acnt_crowd_code  IS NULL )))
      AND (  ir_param.rcv_pay_div IS NOT NULL )
      THEN
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_4_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
--
      --GROUP8
      --PTN08
      --�i�ڋ敪          <> NULL
      --�Q(�o���Q)�R�[�h  <> NULL
      --�󕥋敪          <> NULL
      ELSE
        -- �I�[�v��
        OPEN  get_cur01 FOR lv_select_main_start
                         || lv_select_g1_po102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_po103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_po108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_po108
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om102_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om102
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om101_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om101
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om112_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om112
                         || lv_where2
                         || ' UNION ALL '
                         || lv_select_g1_om103x5_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x5
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om103x124_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om103x124
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om105_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om105
                         || lv_where3
                         || ' UNION ALL '
                         || lv_select_g1_om108_6_hint
                         || lv_select_common
                         || lv_select_group8
                         || lv_select_1_om108
                         || lv_where3
                         || lv_select_main_end
                         ;
        -- �o���N�t�F�b�`
        FETCH get_cur01 BULK COLLECT INTO ot_data_rec ;
        -- �J�[�\���N���[�Y
        CLOSE get_cur01 ;
      END IF;

--
    END IF;
--
-- 2008/10/24 v1.10 ADD END
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF (lc_ref%ISOPEN) THEN
        CLOSE lc_ref ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_report_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬(F-2)
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data (
    ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
   ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000) ;  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- =====================================================
    -- ���[�U�[�錾��
    -- =====================================================
    -- *** ���[�J���萔 ***
    -- �L�[�u���C�N���f�p
    lc_break_init         VARCHAR2(100) DEFAULT '#' ;            -- �����l
    lc_break_null         VARCHAR2(100) DEFAULT '*' ;            -- �m�t�k�k����
--
    -- *** ���[�J���ϐ� ***
    -- �L�[�u���C�N���f�p
-- 2008/10/24 v1.10 ADD START
    --lv_gp_cd1             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�P
    --lv_gp_cd2             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�Q
    --lv_gp_cd3             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�R
    --lv_gp_cd4             VARCHAR2(5)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�S
    lv_gp_cd1             VARCHAR2(10)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�P
    lv_gp_cd2             VARCHAR2(10)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�Q
    lv_gp_cd3             VARCHAR2(10)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�R
    lv_gp_cd4             VARCHAR2(10)   DEFAULT lc_break_init ;              -- �W�v�O���[�v�S
-- 2008/10/24 v1.10 ADD END
    lv_crowd_l            VARCHAR2(1)   DEFAULT lc_break_init ;              -- ��S�v�O���[�v
    lv_crowd_m            VARCHAR2(2)   DEFAULT lc_break_init ;              -- ���S�v�O���[�v
    lv_crowd_s            VARCHAR2(3)   DEFAULT lc_break_init ;              -- ���S�v�O���[�v
    lv_crowd_cd           VARCHAR2(4)   DEFAULT lc_break_init ;              -- �ڌS�v�O���[�v
--
    -- �v�Z�p
    ln_position           NUMBER        DEFAULT 0;               -- �v�Z�p�F�|�W�V����
    ln_i                  NUMBER        DEFAULT 0;               -- �J�E���^�[�p
    lv_trans_qty          NUMBER ;                               -- �������
    lv_tax                NUMBER ;                               -- ����ŗ�
    lv_tax_price          NUMBER ;                               -- �����
    ln_unit_price1        NUMBER ;                               -- �W������
    ln_unit_price2        NUMBER ;                               -- �L������
    ln_unit_price3        NUMBER ;                               -- ���ےP��
    ln_unit_price4        NUMBER ;                               -- �L�|�W�i�����j
    ln_unit_price5        NUMBER ;                               -- �L�|���i�����j
    ln_unit_price6        NUMBER ;                               -- �W�|���i�����j
    lv_price1             NUMBER ;                               -- �W�����z
    lv_price2             NUMBER ;                               -- �L�����z
    lv_price3             NUMBER ;                               -- ���ۋ��z
    lv_price4             NUMBER ;                               -- �L�|�W�i���z�j
    lv_price5             NUMBER ;                               -- �L�|���i���z�j
    lv_price6             NUMBER ;                               -- �W�|���i���z�j
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;             -- �擾���R�[�h�Ȃ�
--
    -- *** ���[�J���֐� ***
    ----------------------
    --1.�w�l�k 1�s�o��   -
    ----------------------
    PROCEDURE prc_xml_add(
       iv_name    IN   VARCHAR2                 --   �^�O�l�[��
      ,ic_type    IN   CHAR                     --   �^�O�^�C�v
      ,iv_data    IN   VARCHAR2 DEFAULT NULL)   --   �f�[�^
    IS
    BEGIN
      gl_xml_idx := gt_xml_data_table.COUNT + 1;
      gt_xml_data_table(gl_xml_idx).tag_name  := iv_name;
      --�f�[�^�̏ꍇ
      IF (ic_type = 'D') THEN
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D';
        gt_xml_data_table(gl_xml_idx).tag_value := iv_data;
      ELSE
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
    END prc_xml_add;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ���ڃf�[�^���o����
    -- =====================================================
    prc_get_report_data(
        ir_param      => ir_param       -- 01.���̓p�����[�^�Q
       ,ot_data_rec   => gt_main_data   -- 02.�擾���R�[�h�Q
       ,ov_errbuf     => lv_errbuf      --    �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode    => lv_retcode     --    ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg     => lv_errmsg      --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_api_expt ;
--
    -- �擾�f�[�^���O���̏ꍇ
    ELSIF ( gt_main_data.COUNT = 0 ) THEN
      RAISE no_data_expt ;
--
    END IF ;
--
    -- =====================================================
    -- ���w�b�_�������ڃf�[�^���o�E�o�͏���
    -- =====================================================
--
    -- -----------------------------------------------------
    -- [USER_INFO] �f�[�^�o��
    -- -----------------------------------------------------
    prc_xml_add('user_info', 'T', NULL);
--
    prc_xml_add('exec_date',          'D', TO_CHAR(gd_exec_date, gc_char_dt_format) ); -- ���{��
    prc_xml_add('report_id',          'D', gv_report_id);                    -- ���[�h�c
    prc_xml_add('exec_user_dept',     'D', SUBSTRB(gv_user_dept,1,10) );     -- �S������
    prc_xml_add('exec_user_name',     'D', SUBSTRB(gv_user_name,1,14) );     -- �S���Җ�
    -- �p�����[�^
    prc_xml_add('p_item_div_code',    'D', ir_param.prod_div );              -- ���i�敪
    prc_xml_add('p_item_div_name',    'D', ir_param.prod_div_name );         -- ���i�敪��
    prc_xml_add('p_party_code',       'D', ir_param.party_code );            -- �o�א�R�[�h
    prc_xml_add('p_party_name',       'D', ir_param.party_name );            -- �o�א於
    prc_xml_add('p_locat_code',       'D', ir_param.whse_code );             -- �q�ɃR�[�h
    prc_xml_add('p_locat_name',       'D', ir_param.whse_name );             -- �q�ɖ�
    prc_xml_add('p_rcv_pay_div_code', 'D', ir_param.rcv_pay_div );           -- �󕥋敪
    prc_xml_add('p_rcv_pay_div_name', 'D', ir_param.rcv_pay_div_name );      -- �󕥋敪��
    prc_xml_add('p_article_div_code', 'D', ir_param.item_div );              -- �i�ڋ敪
    prc_xml_add('p_article_div_name', 'D', ir_param.item_div_name );         -- �i�ڋ敪��
    prc_xml_add('p_result_post_code', 'D', ir_param.result_post );           -- ���ѕ���
    prc_xml_add('p_result_post_name', 'D', ir_param.result_post_name );      -- ���ѕ�����
    -- �����N��(��)
    prc_xml_add('p_trans_ym_from','D', SUBSTRB(ir_param.proc_from,1,4) || '�N'
                                    || SUBSTRB(ir_param.proc_from,5,2) || '��' );
    -- �����N��(��)
    prc_xml_add('p_trans_ym_to',  'D', SUBSTRB(ir_param.proc_to,1,4) || '�N'
                                    || SUBSTRB(ir_param.proc_to,5,2) || '��' );
--
    prc_xml_add('/user_info', 'T', NULL);
--
    -- =====================================================
    -- �����ו������ڃf�[�^���o�E�o�͏���
    -- =====================================================
    ln_i := 1;
    -- -----------------------------------------------------
    -- [DATA_INFO] �J�n�^�O�o��
    -- -----------------------------------------------------
    prc_xml_add('data_info', 'T');
    prc_xml_add('lg_gr1',    'T');
--
    --=============================================�W�v�P���[�v�J�n
    <<group1_loop>>
    WHILE ( ln_i  <= gt_main_data.COUNT )
    LOOP
      prc_xml_add('g_gr1', 'T');
      prc_xml_add('gr1_code',     'D', gt_main_data(ln_i).group1_code);
-- 2008/12/13 v1.16 UPDATE START
--      prc_xml_add('gr1_sum_desc', 'D', gv_gr1_sum_desc);
      prc_xml_add('gr1_sum_desc', 'D', gt_main_data(ln_i).group1_name);
-- 2008/12/13 v1.16 UPDATE END
      lv_gp_cd1  :=  NVL(gt_main_data(ln_i).group1_code, lc_break_null);
      --=============================================�W�v�Q���[�v�J�n
      prc_xml_add('lg_gr2', 'T');
      <<group2_loop>>
      WHILE ( ln_i  <= gt_main_data.COUNT )
        AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
      LOOP
        prc_xml_add('g_gr2', 'T');
        prc_xml_add('gr2_code',     'D', gt_main_data(ln_i).group2_code);
-- 2008/12/13 v1.16 UPDATE START
--        prc_xml_add('gr2_sum_desc', 'D', gv_gr2_sum_desc);
        prc_xml_add('gr2_sum_desc', 'D', gt_main_data(ln_i).group2_name);
-- 2008/12/13 v1.16 UPDATE END
        lv_gp_cd2  :=  NVL(gt_main_data(ln_i).group2_code, lc_break_null);
        --===============================================�W�v�R���[�v�J�n
        prc_xml_add('lg_gr3', 'T');
        <<group3_loop>>
        WHILE ( ln_i  <= gt_main_data.COUNT )
          AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
          AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
        LOOP
          prc_xml_add('g_gr3', 'T');
          prc_xml_add('gr3_code',     'D', gt_main_data(ln_i).group3_code);
-- 2008/12/13 v1.16 UPDATE START
--          prc_xml_add('gr3_sum_desc', 'D', gv_gr3_sum_desc);
          prc_xml_add('gr3_sum_desc', 'D', gt_main_data(ln_i).group3_name);
-- 2008/12/13 v1.16 UPDATE END
          lv_gp_cd3  :=  NVL(gt_main_data(ln_i).group3_code, lc_break_null);
          --================================================�W�v�S���[�v�J�n
          prc_xml_add('lg_gr4', 'T');
          <<group4_loop>>
          WHILE ( ln_i  <= gt_main_data.COUNT )
            AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
            AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
            AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
          LOOP
            prc_xml_add('g_gr4', 'T');
            prc_xml_add('gr4_code',     'D', gt_main_data(ln_i).group4_code);
-- 2008/12/13 v1.16 UPDATE START
--            prc_xml_add('gr4_sum_desc', 'D', gv_gr4_sum_desc);
            prc_xml_add('gr4_sum_desc', 'D', gt_main_data(ln_i).group4_name);
-- 2008/12/13 v1.16 UPDATE END
            lv_gp_cd4  :=  NVL(gt_main_data(ln_i).group4_code, lc_break_null);
            --================================================��S�v���[�v�J�n
            prc_xml_add('lg_crowd_l', 'T');
            <<crowd_l_loop>>
            WHILE ( ln_i  <= gt_main_data.COUNT )
              AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
              AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
              AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
              AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
            LOOP
              prc_xml_add('g_crowd_l', 'T');
              prc_xml_add('crowd_lcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,1) );
              lv_crowd_l  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1), lc_break_null);
              --================================================���S�v���[�v�J�n
              prc_xml_add('lg_crowd_m', 'T');
              <<crowd_m_loop>>
              WHILE ( ln_i  <= gt_main_data.COUNT )
                AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,1),lc_break_null)= lv_crowd_l)
              LOOP
                prc_xml_add('g_crowd_m', 'T');
                prc_xml_add('crowd_mcode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,2) );
                lv_crowd_m  :=  NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2), lc_break_null);
                --================================================���S�v���[�v�J�n
                prc_xml_add('lg_crowd_s', 'T');
                <<crowd_s_loop>>
                WHILE ( ln_i  <= gt_main_data.COUNT )
                  AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                  AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                  AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                  AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                  AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,2),lc_break_null)
                                                                           = lv_crowd_m)
                LOOP
                  prc_xml_add('g_crowd_s', 'T');
                  prc_xml_add('crowd_scode', 'D', SUBSTRB(gt_main_data(ln_i).group5_code,1,3) );
                  lv_crowd_s := NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3), lc_break_null);
                  --================================================�ڌS�v���[�v�J�n
                  prc_xml_add('lg_crowd', 'T');
                  <<crowd_loop>>
                  WHILE ( ln_i  <= gt_main_data.COUNT )
                    AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                    AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                    AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                    AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                    AND ( NVL(SUBSTRB(gt_main_data(ln_i).group5_code,1,3),lc_break_null)
                                                                             = lv_crowd_s)
                  LOOP
                    prc_xml_add('g_crowd', 'T');
                    prc_xml_add('crowd_code', 'D', gt_main_data(ln_i).group5_code );
                    --================================================�i�ڃ��[�v�J�n
                    lv_crowd_cd := NVL(gt_main_data(ln_i).group5_code, lc_break_null);
                    prc_xml_add('lg_item', 'T');
                    <<item_loop>>
                    WHILE ( ln_i  <= gt_main_data.COUNT )
                      AND ( NVL(gt_main_data(ln_i).group1_code, lc_break_null) = lv_gp_cd1)
                      AND ( NVL(gt_main_data(ln_i).group2_code, lc_break_null) = lv_gp_cd2)
                      AND ( NVL(gt_main_data(ln_i).group3_code, lc_break_null) = lv_gp_cd3)
                      AND ( NVL(gt_main_data(ln_i).group4_code, lc_break_null) = lv_gp_cd4)
                      AND ( NVL(gt_main_data(ln_i).group5_code, lc_break_null) = lv_crowd_cd)
                    LOOP
                      prc_xml_add('g_item', 'T');
--
                      -- -----------------------------------------------------
                      -- ������
                      -- -----------------------------------------------------
                      lv_trans_qty   := NULL;    -- �������
                      lv_tax         := NULL;    -- ����ŗ�
                      lv_tax_price   := NULL;    -- �����
                      ln_unit_price1 := NULL;    -- �W������
                      ln_unit_price2 := NULL;    -- �L������
                      ln_unit_price3 := NULL;    -- ���ےP��
                      ln_unit_price4 := NULL;    -- �L�|�W�i�����j
                      ln_unit_price5 := NULL;    -- �L�|���i�����j
                      ln_unit_price6 := NULL;    -- �W�|���i�����j
                      lv_price1      := NULL;    -- �W�����z
                      lv_price2      := NULL;    -- �L�����z
                      lv_price3      := NULL;    -- ���ۋ��z
                      lv_price4      := NULL;    -- �L�|�W�i���z�j
                      lv_price5      := NULL;    -- �L�|���i���z�j
                      lv_price6      := NULL;    -- �W�|���i���z�j
--
                      -- -----------------------------------------------------
                      -- �Z�o�����{�܂�ߏ���
                      -- -----------------------------------------------------
                      -- ����
                      IF  ( NVL(gt_main_data(ln_i).trans_qty,0) != 0 ) THEN
                        lv_trans_qty     := ROUND(gt_main_data(ln_i).trans_qty, 3);
                      END IF;
                      -- �W�����z
                      IF  ( NVL(gt_main_data(ln_i).stnd_price,0) != 0 ) THEN
                        lv_price1        := ROUND(gt_main_data(ln_i).stnd_price);
                        -- �W������
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price1 := ROUND(gt_main_data(ln_i).stnd_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �L�����z
                      IF  ( NVL(gt_main_data(ln_i).price,0) != 0 ) THEN
                        lv_price2        := ROUND(gt_main_data(ln_i).price);
                        -- �L���P��
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price2 := ROUND(gt_main_data(ln_i).price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �����
                      IF  ( NVL(gt_main_data(ln_i).tax,0) != 0 ) THEN
                        lv_tax_price     := ROUND(gt_main_data(ln_i).tax);
                      END IF;
                      -- ���ۋ��z
                      IF  ( NVL(gt_main_data(ln_i).actual_price,0) != 0 ) THEN
                        lv_price3        := ROUND(gt_main_data(ln_i).actual_price);
                        -- ���ی���
                        IF ( NVL(lv_trans_qty,0) != 0 ) THEN
                          ln_unit_price3 := ROUND(gt_main_data(ln_i).actual_price/lv_trans_qty, 2);
                        END IF;
                      END IF;
                      -- �L�|�W(�P��)
                      ln_unit_price4   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price1,0), 2);
                      -- �L�|�W(���z)
                      lv_price4        := ROUND( NVL(lv_price2,0)      - NVL(lv_price1,0) );
                      -- �L�|��(�P��)
                      ln_unit_price5   := ROUND( NVL(ln_unit_price2,0) - NVL(ln_unit_price3,0), 2);
                      -- �L�|��(���z)
                      lv_price5        := ROUND( NVL(lv_price2,0)      - NVL(lv_price3,0) );
                      -- �W�|��(�P��)
                      ln_unit_price6   := ROUND( NVL(ln_unit_price1,0) - NVL(ln_unit_price3,0), 2);
                      -- �W�|��(���z)
                      lv_price6        := ROUND( NVL(lv_price1,0)      - NVL(lv_price3,0) );
--
                      -- -----------------------------------------------------
                      -- XML�o��
                      -- -----------------------------------------------------
                      -- �o�וi�ڃR�[�h�E�o�וi�ږ���
                      prc_xml_add('req_item_code','D', gt_main_data(ln_i).req_item_code );
                      prc_xml_add('req_item_name','D', gt_main_data(ln_i).req_item_name );
                      -- �i�ڃR�[�h�E�i�ږ���
                      prc_xml_add('item_code'    ,'D', gt_main_data(ln_i).item_code );
                      prc_xml_add('item_name'    ,'D', gt_main_data(ln_i).item_name );
                      -- �P��
                      prc_xml_add('item_um'      ,'D', gt_main_data(ln_i).trans_um );
                      -- ����
                      prc_xml_add('trans_qty'  ,'D', NVL(lv_trans_qty,0) );
                      -- �����
                      prc_xml_add('tax_price'  ,'D', NVL(lv_tax_price,0) );
                      -- �W������
                      prc_xml_add('unit_price1','D', NVL(ln_unit_price1,0) );
                      -- �W�����z
                      prc_xml_add('price1'     ,'D', NVL(lv_price1,0) );
                      -- �L���P��
                      prc_xml_add('unit_price2','D', NVL(ln_unit_price2,0) );
                      -- �L�����z
                      prc_xml_add('price2'     ,'D', NVL(lv_price2,0) );
                      -- ���ی���
                      prc_xml_add('unit_price3','D', NVL(ln_unit_price3,0) );
                      -- ���ۋ��z
                      prc_xml_add('price3'     ,'D', NVL(lv_price3,0) );
                      -- �L�|�W�i�����j
                      prc_xml_add('unit_price4','D', NVL(ln_unit_price4,0) );
                      -- �L�|�W�i���z�j
                      prc_xml_add('price4'     ,'D', NVL(lv_price4,0) );
                      -- �L�|���i�����j
                      prc_xml_add('unit_price5','D', NVL(ln_unit_price5,0) );
                      -- �L�|���i���z�j
                      prc_xml_add('price5'     ,'D', NVL(lv_price5,0) );
                      -- �W�|���i�P���j
                      prc_xml_add('unit_price6','D', NVL(ln_unit_price6,0) );
                      -- �W�|���i���z�j
                      prc_xml_add('price6'     ,'D', NVL(lv_price6,0) );
                      -- �����J�E���g
                      prc_xml_add('item_position' ,'D', ln_i );
--
                      ln_i  :=  ln_i  + 1; --�����׈ʒu
                      prc_xml_add('/g_item', 'T');
                    END LOOP  item_loop;
                    prc_xml_add('/lg_item', 'T');
                    --================================================�ڌS�v���[�v�I��
                    prc_xml_add('/g_crowd', 'T');
                  END LOOP  crowd_loop;
                  prc_xml_add('/lg_crowd', 'T');
                  --================================================�ڌS�v���[�v�I��
                  prc_xml_add('/g_crowd_s', 'T');
                END LOOP  crowd_s_loop;
                prc_xml_add('/lg_crowd_s', 'T');
                --================================================���S�v���[�v�I��
                prc_xml_add('/g_crowd_m', 'T');
              END LOOP  crowd_m_loop;
              prc_xml_add('/lg_crowd_m', 'T');
              --================================================���S�v���[�v�I��
              prc_xml_add('/g_crowd_l', 'T');
            END LOOP  crowd_l_loop;
            prc_xml_add('/lg_crowd_l', 'T');
          --================================================��S�v���[�v�I��
          prc_xml_add('/g_gr4', 'T');
          END LOOP  group4_loop;
          prc_xml_add('/lg_gr4', 'T');
          --================================================�W�v�S���[�v�I��
          prc_xml_add('/g_gr3', 'T');
        END LOOP  group3_loop;
        prc_xml_add('/lg_gr3', 'T');
        --================================================�W�v�R���[�v�I��
        prc_xml_add('/g_gr2', 'T');
      END LOOP  group2_loop;
      prc_xml_add('/lg_gr2', 'T');
      --================================================�W�v�Q���[�v�I��
      --�ŏI���R�[�h�̏ꍇ�A�����v�s�o�̓t���O��ON�ɂ���B
      IF (ln_i > gt_main_data.COUNT) THEN
        prc_xml_add('last_recode_flg', 'D', 'Y');
      ELSE
        prc_xml_add('last_recode_flg', 'D', 'N');
      END IF;
      prc_xml_add('/g_gr1', 'T');
    END LOOP  group1_loop;
    prc_xml_add('/lg_gr1', 'T');
    --================================================�W�v�P���[�v�I��
--
    prc_xml_add('/data_info', 'T'); --�f�[�^�I��
--
  EXCEPTION
    -- *** �擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10122' ) ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain (
    iv_proc_from          IN    VARCHAR2  --   01 : �����N��FROM
   ,iv_proc_to            IN    VARCHAR2  --   02 : �����N��TO
   ,iv_rcv_pay_div        IN    VARCHAR2  --   03 : �󕥋敪
   ,iv_prod_div           IN    VARCHAR2  --   04 : ���i�敪
   ,iv_item_div           IN    VARCHAR2  --   05 : �i�ڋ敪
   ,iv_result_post        IN    VARCHAR2  --   06 : ���ѕ���
   ,iv_whse_code          IN    VARCHAR2  --   07 : �q�ɃR�[�h
   ,iv_party_code         IN    VARCHAR2  --   08 : �o�א�R�[�h
   ,iv_crowd_type         IN    VARCHAR2  --   09 : �S���
   ,iv_crowd_code         IN    VARCHAR2  --   10 : �S�R�[�h
   ,iv_acnt_crowd_code    IN    VARCHAR2  --   11 : �o���Q�R�[�h
   ,iv_output_type        IN    VARCHAR2  --   12 : �o�͎��
   ,ov_errbuf            OUT    VARCHAR2  -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode           OUT    VARCHAR2  -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg            OUT    VARCHAR2  -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'submain' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf  VARCHAR2(5000) ;                   --   �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1) ;                      --   ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000) ;                   --   ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ======================================================
    -- ���[�U�[�錾��
    -- ======================================================
    -- *** ���[�J���ϐ� ***
    lr_param_rec            rec_param_data ;          -- �p�����[�^��n���p
--
    lv_xml_string           VARCHAR2(32000) ;
    ln_retcode              NUMBER ;
--
    lv_work_date            VARCHAR2(30); -- �ϊ��p
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal ;
--
--###########################  �Œ蕔 END   ############################
--
    -- =====================================================
    -- ��������
    -- =====================================================
    -- ���[�o�͒l�i�[
    gv_report_id                 := iv_output_type || 'T' ;-- ���[ID
    gd_exec_date                 := SYSDATE ;              -- ���{��
    -- �p�����[�^�i�[
    -- �����N��FROM
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_from, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_from     := iv_proc_from;
    ELSE
      lr_param_rec.proc_from     := lv_work_date;
    END IF;
    -- �����N��TO
    lv_work_date :=
      TO_CHAR(FND_DATE.STRING_TO_DATE( iv_proc_to, gc_char_m_format ), gc_char_m_format );
    IF ( lv_work_date IS NULL ) THEN
      lr_param_rec.proc_to     := iv_proc_to;
    ELSE
      lr_param_rec.proc_to     := lv_work_date;
    END IF;
    lr_param_rec.rcv_pay_div     := iv_rcv_pay_div;        -- �󕥋敪
    lr_param_rec.prod_div        := iv_prod_div;           -- ���i�敪
    lr_param_rec.item_div        := iv_item_div;           -- �i�ڋ敪
    lr_param_rec.result_post     := iv_result_post;        -- ���ѕ���
    lr_param_rec.whse_code       := iv_whse_code;          -- �q�ɃR�[�h
    lr_param_rec.party_code      := iv_party_code;         -- �o�א�R�[�h
    lr_param_rec.crowd_type      := iv_crowd_type;         -- �S���
    lr_param_rec.crowd_code      := iv_crowd_code;         -- �S�R�[�h
    lr_param_rec.acnt_crowd_code := iv_acnt_crowd_code;    -- �o���Q�R�[�h
    lr_param_rec.output_type     := iv_output_type;        -- �o�͎��
--
    -- =====================================================
    -- �O����
    -- =====================================================
    prc_initialize(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- ���[�f�[�^�o��
    -- =====================================================
    prc_create_xml_data(
        ir_param          => lr_param_rec       -- ���̓p�����[�^�Q
       ,ov_errbuf         => lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        => lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         => lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- �w�l�k�o��
    -- ==================================================
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- --------------------------------------------------
    -- ���o�f�[�^���O���̏ꍇ
    -- --------------------------------------------------
    IF  ( lv_errmsg IS NOT NULL )
    AND ( lv_retcode = gv_status_warn ) THEN
      -- �O�����b�Z�[�W�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>') ;
--
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <user_info>') ;
      -- �w�l�k�^�O�o�� �� ���{��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_date>'
                                       ||    TO_CHAR(gd_exec_date, gc_char_dt_format)
                                       || '</exec_date>'
                       );
      -- �w�l�k�^�O�o�� �� ���[�h�c
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<report_id>'
                                       ||    gv_report_id
                                       || '</report_id>'
                       );
      -- �w�l�k�^�O�o�� �� �S������
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_dept>'
                                       ||    SUBSTRB(gv_user_dept,1,20)
                                       || '</exec_user_dept>'
                       );
      -- �w�l�k�^�O�o�� �� �S���Җ�
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<exec_user_name>'
                                       ||    SUBSTRB(gv_user_name,1,20)
                                       || '</exec_user_name>'
                       );
      -- �w�l�k�^�O�o�́F���i�敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_code>'
                                       ||    lr_param_rec.prod_div
                                       || '</p_item_div_code>'
                       );
      -- �w�l�k�^�O�o�́F���i�敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_item_div_name>'
                                       ||    lr_param_rec.prod_div_name
                                       || '</p_item_div_name>'
                       );
      -- �w�l�k�^�O�o�� �o�א�R�[�h
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_code>'
                                       ||    lr_param_rec.party_code
                                       || '</p_party_code>'
                       );
      -- �w�l�k�^�O�o�� �o�א於
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_party_name>'
                                       ||    lr_param_rec.party_name
                                       || '</p_party_name>'
                       );
      -- �w�l�k�^�O�o�� �q�ɃR�[�h
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_code>'
                                       ||    lr_param_rec.whse_code
                                       || '</p_locat_code>'
                       );
      -- �w�l�k�^�O�o�� �q�ɖ�
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_locat_name>'
                                       ||    lr_param_rec.whse_name
                                       || '</p_locat_name>'
                       );
      -- �w�l�k�^�O�o�� �� �󕥋敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_code>'
                                       ||    lr_param_rec.rcv_pay_div
                                       || '</p_rcv_pay_div_code>'
                       );
      -- �w�l�k�^�O�o�� �� �󕥋敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_rcv_pay_div_name>'
                                       ||    lr_param_rec.rcv_pay_div_name
                                       || '</p_rcv_pay_div_name>'
                       );
      -- �w�l�k�^�O�o�� �� �i�ڋ敪
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_code>'
                                       ||    lr_param_rec.item_div
                                       || '</p_article_div_code>'
                       );
      -- �w�l�k�^�O�o�� �� �i�ڋ敪��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_article_div_name>'
                                       ||    lr_param_rec.item_div_name
                                       || '</p_article_div_name>'
                       );
      -- �w�l�k�^�O�o�� �� ���ѕ���
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_code>'
                                       ||    lr_param_rec.result_post
                                       || '</p_result_post_code>'
                       );
      -- �w�l�k�^�O�o�� �� ���ѕ�����
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_result_post_name>'
                                       ||    lr_param_rec.result_post_name
                                       || '</p_result_post_name>'
                       );
      -- �w�l�k�^�O�o�� �� �����N��(��)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_from>'
                                       ||    SUBSTRB(lr_param_rec.proc_from,1,4) || '�N'
                                       ||    SUBSTRB(lr_param_rec.proc_from,5,2) || '��'
                                       || '</p_trans_ym_from>'
                       );
      -- �w�l�k�^�O�o�� �� �����N��(��)
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<p_trans_ym_to>'
                                       ||    SUBSTRB(lr_param_rec.proc_to,1,4) || '�N'
                                       ||    SUBSTRB(lr_param_rec.proc_to,5,2) || '��'
                                       || '</p_trans_ym_to>'
                       );
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </user_info>') ;
--
      -- ��data_info��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  <data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    <lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      <g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        <lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          <g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            <lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              <g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                <lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  <g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    <lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      <g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        <lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          <g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            <lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              <g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                <lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  <g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, ' <msg>' || lv_errmsg || '</msg>' ) ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                  </g_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                                </lg_crowd>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                              </g_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                            </lg_crowd_s>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                          </g_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                        </lg_crowd_m>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                      </g_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                    </lg_crowd_l>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                  </g_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '                </lg_gr4>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '              </g_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '            </lg_gr3>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '          </g_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '        </lg_gr2>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '      </g_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '    </lg_gr1>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '  </data_info>') ;
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>') ;
--
      -- �O�����b�Z�[�W���O�o��
      lv_errmsg  := xxcmn_common_pkg.get_msg( gc_application
                                             ,'APP-XXCMN-10154'
                                             ,'TABLE'
                                             ,gv_print_name ) ;
--
    -- --------------------------------------------------
    -- ���[�f�[�^���o�͂ł����ꍇ
    -- --------------------------------------------------
    ELSE
      -- �w�l�k�w�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
--
      -- �w�l�k�f�[�^���o��
      <<xml_data_table>>
      FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
        -- �ҏW�����f�[�^���^�O�ɕϊ�
        lv_xml_string := fnc_conv_xml
                          (
                            iv_name   => gt_xml_data_table(i).tag_name    -- �^�O�l�[��
                           ,iv_value  => gt_xml_data_table(i).tag_value   -- �^�O�f�[�^
                           ,ic_type   => gt_xml_data_table(i).tag_type    -- �^�O�^�C�v
                          ) ;
        -- �w�l�k�^�O�o��
        FND_FILE.PUT_LINE( FND_FILE.OUTPUT, lv_xml_string ) ;
      END LOOP xml_data_table ;
--
      -- �w�l�k�t�b�_�[�o��
      FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
--
    END IF ;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      ov_retcode := gv_status_error ;
--
--####################################  �Œ蕔 END   ##########################################
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
      errbuf             OUT   VARCHAR2  -- �G���[���b�Z�[�W
     ,retcode            OUT   VARCHAR2  -- �G���[�R�[�h
     ,iv_proc_from       IN    VARCHAR2  --   01 : �����N��FROM
     ,iv_proc_to         IN    VARCHAR2  --   02 : �����N��TO
     ,iv_rcv_pay_div     IN    VARCHAR2  --   03 : �󕥋敪
     ,iv_prod_div        IN    VARCHAR2  --   04 : ���i�敪
     ,iv_item_div        IN    VARCHAR2  --   05 : �i�ڋ敪
     ,iv_result_post     IN    VARCHAR2  --   06 : ���ѕ���
     ,iv_whse_code       IN    VARCHAR2  --   07 : �q�ɃR�[�h
     ,iv_party_code      IN    VARCHAR2  --   08 : �o�א�R�[�h
     ,iv_crowd_type      IN    VARCHAR2  --   09 : �S���
     ,iv_crowd_code      IN    VARCHAR2  --   10 : �S�R�[�h
     ,iv_acnt_crowd_code IN    VARCHAR2  --   11 : �o���Q�R�[�h
     ,iv_output_type     IN    VARCHAR2  --   12 : �o�͎��
    )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ======================================================
    -- �Œ胍�[�J���萔
    -- ======================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ======================================================
    -- ���[�J���ϐ�
    -- ======================================================
    lv_errbuf               VARCHAR2(5000) ;      --   �G���[�E���b�Z�[�W
    lv_retcode              VARCHAR2(1) ;         --   ���^�[���E�R�[�h
    lv_errmsg               VARCHAR2(5000) ;      --   ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ======================================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ======================================================
    submain(
        iv_proc_from        => iv_proc_from         --   01 : �����N��FROM
       ,iv_proc_to          => iv_proc_to           --   02 : �����N��TO
       ,iv_rcv_pay_div      => iv_rcv_pay_div       --   03 : �󕥋敪
       ,iv_prod_div         => iv_prod_div          --   04 : ���i�敪
       ,iv_item_div         => iv_item_div          --   05 : �i�ڋ敪
       ,iv_result_post      => iv_result_post       --   06 : ���ѕ���
       ,iv_whse_code        => iv_whse_code         --   07 : �q�ɃR�[�h
       ,iv_party_code       => iv_party_code        --   08 : �o�א�R�[�h
       ,iv_crowd_type       => iv_crowd_type        --   09 : �S���
       ,iv_crowd_code       => iv_crowd_code        --   10 : �S�R�[�h
       ,iv_acnt_crowd_code  => iv_acnt_crowd_code   --   11 : �o���Q�R�[�h
       ,iv_output_type      => iv_output_type       --   12 : �o�͎��
       ,ov_errbuf           => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode          => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg           => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF  ( lv_retcode = gv_status_error )
     OR ( lv_retcode = gv_status_warn  ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG,lv_errbuf) ;
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM ;
      retcode := gv_status_error ;
  END main ;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxcmn770026c ;
/
