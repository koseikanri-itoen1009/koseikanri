CREATE OR REPLACE PACKAGE BODY xxwsh620004c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2008. All rights reserved.
 *
 * Package Name     : xxwsh620004c(body)
 * Description      : �q�ɕ��o�w����
 * MD.050           : ����/�z��(���[) T_MD050_BPO_621
 * MD.070           : �q�ɕ��o�w����  T_MD070_BPO_62F
 * Version          : 1.5
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  prc_initialize         PROCEDURE : ��������
 *  prc_get_report_data    PROCEDURE : ���[�f�[�^�擾����
 *  prc_create_xml_data    PROCEDURE : XML��������
 *  fnc_convert_into_xml   FUNCTION  : XML�f�[�^�ϊ�
 *  submain                PROCEDURE : ���C�������v���V�[�W��
 *  main                   PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/05/02    1.0   Yuki Komikado    �V�K�쐬
 *  2008/06/24    1.1   Masayoshi Uehara   �x���̏ꍇ�A�p�����[�^�z����/���ɐ�̃����[�V������
 *                                         vendor_site_code�ɕύX�B
 *  2008/07/02    1.2   Satoshi Yunba    �֑������Ή�
 *  2008/07/18    1.3   Hitomi Itou      ST�s�#465�Ή� �o�Ɍ��E�u���b�N�̒��o������ύX
 *  2008/08/07    1.4   Akiyoshi Shiina  �����ύX�v��#168,#183�Ή�
 *  2008/10/20    1.5   Masayoshi Uehara T_TE080_BPO_620 �w�E44(�i�ځA���b�g�P�ʂɍ��v���ĎZ�o)
 *                                       �ۑ�#62�ύX#168 �w���������т̒��[�o�͐���
 *
 *****************************************************************************************/
--
--#######################  �Œ�O���[�o���萔�錾�� START   #######################
--
  gv_status_normal CONSTANT VARCHAR2(1) := '0';
  gv_status_warn   CONSTANT VARCHAR2(1) := '1';
  gv_status_error  CONSTANT VARCHAR2(1) := '2';
  gv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  gv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  �Œ蕔 END   ###############################
--
--#######################  �Œ�O���[�o���ϐ��錾�� START   #######################
--
--################################  �Œ蕔 END   ###############################
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--###########################  �Œ蕔 END   ############################
--
  -- ===============================
  -- ���[�U�[��`��O
  -- ===============================
  --*** ���������ʗ�O ***
  no_data_expt       EXCEPTION;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���萔
  -- ===============================
  gv_pkg_name                CONSTANT  VARCHAR2(100) := 'xxwsh620004c' ;     -- �p�b�P�[�W��
  gc_report_id               CONSTANT  VARCHAR2(12) := 'XXWSH620004T' ;      -- ���[ID
  -- �X�e�[�^�X
  gc_req_status_shimezumi    CONSTANT  VARCHAR2(2)  := '03' ;                 -- ���ߍς�
  gc_req_status_juryozumi    CONSTANT  VARCHAR2(2)  := '07' ;                 -- ��̍�
  gc_req_status_torikeshi    CONSTANT  VARCHAR2(2)  := '99' ;                 -- ���
  -- �ŐV�t���O
  gc_latest_external_flag    CONSTANT  VARCHAR2(1)  := 'Y' ;
  -- �o�׎x���敪 
  gc_shipping_shikyu_syukka  CONSTANT  VARCHAR2(1)  := '1' ;                  -- �o�׈˗�
  gc_shipping_shikyu_shikyu  CONSTANT  VARCHAR2(1)  := '2' ;                  -- �x���˗�
  -- �󒍃J�e�S��
  gc_order_category_code     CONSTANT  VARCHAR2(6)  := 'RETURN' ;             -- �ԕi
  -- �폜�t���O
  gc_delete_flag             CONSTANT  VARCHAR2(1)  := 'Y' ;
-- ADD START 2008/10/20 1.5
  -- �w���Ȃ����ы敪
  gc_no_instr_actual_class   CONSTANT  VARCHAR2(1)  := 'Y' ;                 -- �w���Ȃ�����
-- ADD END 2008/10/20 1.5
  -- �����^�C�v
  gc_doc_type_code_mv        CONSTANT  VARCHAR2(2)  := '20' ;                -- �ړ�
  gc_doc_type_code_syukka    CONSTANT  VARCHAR2(2)  := '10' ;                -- �o�׈˗�
  gc_doc_type_code_shikyu    CONSTANT  VARCHAR2(2)  := '30' ;                -- �x���w��
  -- ���R�[�h�^�C�v
  gc_rec_type_code_ins       CONSTANT  VARCHAR2(2)  := '10' ;                -- �w��
  -- �N�C�b�N�R�[�h
  gc_lookup_type_621b_int    CONSTANT  VARCHAR2(30) := 'XXWSH_621B_INT_EXT_CLASS' ;
  -- �ړ��^�C�v
  gc_mov_type_not_ship       CONSTANT  VARCHAR2(5)  := '2' ;                 -- �ϑ��Ȃ�
  -- �ړ��X�e�[�^�X
  gc_status_reqed            CONSTANT  VARCHAR2(2)  := '02' ;                -- �˗���
  gc_status_not              CONSTANT  VARCHAR2(2)  := '99' ;                -- ���
  -- ���i�敪
  gc_item_cd_prdct           CONSTANT  VARCHAR2(1)  := '5' ;                 -- ���i
  -- ���t�t�H�[�}�b�g
  gc_date_fmt_all            CONSTANT  VARCHAR2(21) := 'YYYY/MM/DD HH24:MI:SS' ; -- �N���������b
  gc_date_fmt_ymd            CONSTANT  VARCHAR2(10) := 'YYYY/MM/DD' ;            -- �N����
  -- �o�̓^�O
  gc_tag_type_tag            CONSTANT  VARCHAR2(1)  := 'T' ;                 -- �O���[�v�^�O
  gc_tag_type_data           CONSTANT  VARCHAR2(1)  := 'D' ;                 -- �f�[�^�^�O
  -- �Ɩ����
  gc_biz_type_cd_ship        CONSTANT  VARCHAR2(1)  := '1' ;        -- �o��
  gc_biz_type_cd_shikyu      CONSTANT  VARCHAR2(1)  := '2' ;        -- �x��
  gc_biz_type_cd_move        CONSTANT  VARCHAR2(1)  := '3' ;        -- �ړ�
  gc_biz_type_nm_ship        CONSTANT  VARCHAR2(4)  := '�o��' ;     -- �o��
  gc_biz_type_nm_shik        CONSTANT  VARCHAR2(4)  := '�x��' ;     -- �x��
  gc_biz_type_nm_move        CONSTANT  VARCHAR2(4)  := '�ړ�' ;     -- �ړ�
--
  ------------------------------
  -- �G���[���b�Z�[�W�֘A
  ------------------------------
  --�A�v���P�[�V������
  gc_application_wsh         CONSTANT VARCHAR2(5)   := 'XXWSH' ;             -- ��޵�:�o�ץ������z��
  gc_application_cmn         CONSTANT VARCHAR2(5)   := 'XXCMN' ;             -- ��޵�:�o�ץ������z��
  --���b�Z�[�WID
  gc_msg_id_required         CONSTANT  VARCHAR2(15) := 'APP-XXWSH-12452' ;   -- ���Ұ������װ
  gc_msg_id_no_data          CONSTANT  VARCHAR2(15) := 'APP-XXCMN-10122' ;   -- ���[0���G���[
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
  ------------------------------
  -- ���̓p�����[�^�֘A
  ------------------------------
  -- ���̓p�����[�^�i�[�p���R�[�h
  TYPE rec_param_data IS RECORD(
     business_typ       VARCHAR2(4)     -- 01 : �Ɩ����
    ,deliver_type       NUMBER          -- 02 : �o�Ɍ`��
    ,block              VARCHAR2(6)     -- 03 : �u���b�N
    ,deliver_from       VARCHAR2(9)     -- 04 : �o�Ɍ�
    ,deliver_to         VARCHAR2(9)     -- 05 : �z����^���ɐ�
    ,prod_div           VARCHAR2(2)     -- 06 : ���i�敪
    ,item_div           VARCHAR2(2)     -- 07 : �i�ڋ敪
    ,date_from          DATE            -- 08 : �o�ɓ�
  );
  type_rec_param_data   rec_param_data ;
--
  ------------------------------
  -- �o�̓f�[�^�֘A
  ------------------------------
  -- ���R�[�h�錾�p
  xoha    xxwsh_order_headers_all%ROWTYPE ;         -- �󒍃w�b�_�A�h�I��
  xott2v  xxwsh_oe_transaction_types2_v%ROWTYPE ;   -- �󒍃^�C�v���VIEW2
  xola    xxwsh_order_lines_all%ROWTYPE ;           -- �󒍖��׃A�h�I��
  xim2v   xxcmn_item_mst2_v%ROWTYPE ;               -- OPM�i�ڏ��VIEW2
-- 2008/08/07 v1.4 UPDATE START
--  xic3v   xxcmn_item_categories3_v%ROWTYPE ;        -- OPM�i�ڃJ�e�S���������VIEW3
  xic2v   xxcmn_item_categories2_v%ROWTYPE ;        -- OPM�i�ڃJ�e�S���������VIEW2
-- 2008/08/07 v1.4 UPDATE END
  xmld    xxinv_mov_lot_details%ROWTYPE ;           -- �ړ����b�g�ڍ�(�A�h�I��)
  ilm     ic_lots_mst%ROWTYPE ;                     -- OPM���b�g�}�X�^
  xil2v   xxcmn_item_locations2_v%ROWTYPE ;         -- OPM�ۊǏꏊ���VIEW2
  xlv2v   xxcmn_lookup_values2_v%ROWTYPE ;          -- �N�C�b�N�R�[�h���VIEW2
  xcas2v  xxcmn_cust_acct_sites2_v%ROWTYPE ;        -- �ڋq�T�C�g���VIEW2
--
  -- �o�̓f�[�^�i�[�p���R�[�h
  TYPE rec_report_data IS RECORD(
       trans_type            xott2v.transaction_type_name%TYPE  -- �o�Ɍ`��
      ,ship_cd               xoha.deliver_from%TYPE             -- �o�Ɍ�
      ,ship_nm               xil2v.description%TYPE             -- �o�Ɍ�(����)
      ,delivery_to_cd        xoha.deliver_to%TYPE               -- �z����/���ɐ�i�R�[�h�j
      ,delivery_to_nm        xcas2v.party_site_full_name%TYPE   -- �z����/���ɐ�i���́j
-- 2008/08/07 v1.4 UPDATE START
--      ,item_class            xic3v.item_class_name%TYPE         -- �i�ڋ敪��
      ,item_class            xic2v.description%TYPE             -- �i�ڋ敪��
-- 2008/08/07 v1.4 UPDATE END
      ,ship_date             xoha.schedule_ship_date%TYPE       -- �o�ɓ�
-- 2008/08/07 v1.4 UPDATE START
--      ,in_out_class_code     xic3v.int_ext_class%TYPE           -- ���O�敪�i���Б��Ћ敪�R�[�h�j
      ,in_out_class_code     xic2v.segment1%TYPE                -- ���O�敪�i���Б��Ћ敪�R�[�h�j
-- 2008/08/07 v1.4 UPDATE END
      ,int_ext_class         xlv2v.meaning%TYPE                 -- ���O�敪
      ,item_cd               xola.shipping_item_code%TYPE       -- �i�ځi�R�[�h�j
      ,item_nm               xim2v.item_short_name%TYPE         -- �i�ځi���́j
      ,qty                   xola.quantity%TYPE                 -- ���v��
      ,qty_tani              xim2v.item_um%TYPE                 -- ���o�Ɋ��Z�P��
      ,lot_no                xmld.lot_no%TYPE                   -- ���b�gNo
      ,prod_date             ilm.attribute1%TYPE                -- ������
      ,best_before_date      ilm.attribute3%TYPE                -- �ܖ�����
      ,native_sign           ilm.attribute2%TYPE                -- �ŗL�L��
      ,trans_type_id         xoha.order_type_id%TYPE            -- �o�Ɍ`��(ID)
-- 2008/08/07 v1.4 UPDATE START
--      ,item_class_code       xic3v.item_class_code%TYPE         -- �i�ڋ敪�R�[�h
      ,item_class_code       xic2v.segment1%TYPE                -- �i�ڋ敪�R�[�h
-- 2008/08/07 v1.4 UPDATE END
  );
  type_report_data      rec_report_data;
  TYPE list_report_data IS TABLE OF rec_report_data INDEX BY BINARY_INTEGER ;
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  gt_param              rec_param_data ;      -- ���̓p�����[�^���
  gt_report_data        list_report_data ;    -- �o�̓f�[�^
  gt_xml_data_table     XML_DATA ;            -- XML�f�[�^
  gv_dept_cd            VARCHAR2(10) ;        -- �S������
  gv_dept_nm            VARCHAR2(14) ;        -- �S����
  gv_biz_kind           VARCHAR2(10) ;        -- �Ɩ����
  gd_common_sysdate     DATE;                 -- �V�X�e�����t
--
  /**********************************************************************************
   * Procedure Name   : prc_initialize
   * Description      : ��������
   ***********************************************************************************/
  PROCEDURE prc_initialize(
    ov_errbuf     OUT  VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2         -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT  VARCHAR2(100) := 'prc_initialize' ;  -- �v���O������
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
    -- *** ���[�J���E��O���� ***
    prm_check_expt     EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
    get_prof_expt      EXCEPTION ;     -- �v���t�@�C���擾��O
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    gd_common_sysdate := SYSDATE ;    -- �V�X�e�����t
--
    -- ====================================================
    -- �p�����[�^�`�F�b�N
    -- ====================================================
    IF (( gt_param.deliver_from IS NULL ) AND ( gt_param.block IS NULL )) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wsh
                                            ,gc_msg_id_required
                                           ) ;
      RAISE prm_check_expt ;
    END IF ;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O�n���h�� ***
    WHEN prm_check_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_error ;
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
  END prc_initialize;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_report_data
   * Description      : ���[�f�[�^�擾����
   ***********************************************************************************/
  PROCEDURE prc_get_report_data(
    ov_errbuf      OUT   VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode     OUT   VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg      OUT   VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_report_data' ;  -- �v���O������
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
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_ship_data
    IS
    SELECT
       xott2v.transaction_type_name         AS  trans_type        -- �o�Ɍ`��
      ,xoha.deliver_from                    AS  ship_cd           -- �o�Ɍ�
      ,xil2v.description                    AS  ship_nm           -- �o�Ɍ�(����)
--MOD START 2008/10/20 1.5 
--      ,xoha.deliver_to                      AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
--      ,xcas2v.party_site_full_name          AS  delivery_to_nm    -- �z����/���ɐ�i���́j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xoha.deliver_to)                  AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xcas2v.party_site_full_name)       AS  delivery_to_nm    -- �z����/���ɐ�i���́j
--MOD END 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- �i�ڋ敪��
      ,xic5v.item_class_name                AS  item_class        -- �i�ڋ敪��
-- 2008/08/07 v1.4 UPDATE END
      ,xoha.schedule_ship_date              AS  ship_date         -- �o�ɓ�
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
      ,mcb.attribute1                       AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                        AS  int_ext_class     -- ���O�敪
      ,xola.shipping_item_code              AS  item_cd           -- �i�ځi�R�[�h�j
      ,xim2v.item_short_name                AS  item_nm           -- �i�ځi���́j
      ,CASE                                     
        -- ��������Ă���ꍇ
        WHEN ( SUM(xola.reserved_quantity) > 0 ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--              xmld.actual_quantity / TO_NUMBER(
              SUM(xmld.actual_quantity) / TO_NUMBER(
-- 2008/10/20 1.5 MOD END
                                                CASE
                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                    xim2v.num_of_cases
                                                  ELSE
                                                    TO_CHAR(1)
                                                END
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--                                              )
                                              )
-- 2008/10/20 1.5 MOD END
            ELSE
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--              xmld.actual_quantity
              SUM(xmld.actual_quantity)
-- 2008/10/20 1.5 MOD END
            END
        -- ��������Ă��Ȃ��ꍇ
        WHEN  ( ( SUM(xola.reserved_quantity) IS NULL ) OR ( SUM(xola.reserved_quantity) = 0 ) ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--              xola.quantity / TO_NUMBER(
              SUM(xola.quantity) / TO_NUMBER(
-- 2008/10/20 1.5 MOD END
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--                                       )
                                       )
-- 2008/10/20 1.5 MOD END
            ELSE
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--              xola.quantity
              SUM(xola.quantity)
-- 2008/10/20 1.5 MOD END
            END
        END                                 AS  qty               -- ���v��
      ,CASE
       -- �����@
-- 2008/08/07 v1.4 UPDATE START
--       WHEN (    xic3v.item_class_code = gc_item_cd_prdct
       WHEN (    xic5v.item_class_code = gc_item_cd_prdct
-- 2008/08/07 v1.4 UPDATE END
             AND xim2v.conv_unit IS NOT NULL) THEN
         xim2v.conv_unit
       ELSE
         -- �����A
         xim2v.item_um
       END                                  AS  qty_tani          -- ���o�Ɋ��Z�P��
      ,xmld.lot_no                          AS  lot_no            -- ���b�gNo
      ,ilm.attribute1                       AS  prod_date         -- ������
      ,ilm.attribute3                       AS  best_before_date  -- �ܖ�����
      ,ilm.attribute2                       AS  native_sign       -- �ŗL�L��
      ,xoha.order_type_id                   AS  order_type_id     -- �o�Ɍ`�ԁiID�j
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
      ,xic5v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxwsh_order_headers_all                xoha                  -- �󒍃w�b�_�A�h�I��
      ,xxwsh_oe_transaction_types2_v          xott2v                -- �󒍃^�C�v���VIEW2
      ,xxwsh_order_lines_all                  xola                  -- �󒍖��׃A�h�I��
      ,xxcmn_item_mst2_v                      xim2v                 -- OPM�i�ڏ��VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM�i�ڃJ�e�S���������VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM�i�ڃJ�e�S���������VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld                  -- �ړ����b�g�ڍ�(�A�h�I��)
      ,ic_lots_mst                            ilm                   -- OPM���b�g�}�X�^
      ,xxcmn_item_locations2_v                xil2v                 -- OPM�ۊǏꏊ���VIEW2
      ,xxcmn_cust_acct_sites2_v               xcas2v                -- �ڋq�T�C�g���VIEW2
      ,xxcmn_lookup_values2_v                 xlv2v                 -- �N�C�b�N�R�[�h���VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      -------------------------------------------------------------------------------
            xoha.req_status                   >= gc_req_status_shimezumi  -- ���ߍς�
      AND   xoha.req_status                   <> gc_req_status_torikeshi  -- ���
      AND   (gt_param.deliver_to IS NULL
             OR
             xoha.deliver_to                   = gt_param.deliver_to )
                                                                      -- �p�����[�^�F�z����/���ɐ�
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xoha.deliver_from                = gt_param.deliver_from )  -- �p�����[�^�F�o�Ɍ�
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v.distribution_block         = gt_param.block )         -- �p�����[�^�F�u���b�N
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- �p�����[�^�F�o�Ɍ��A�p�����[�^�F�u���b�N��NULL�̏ꍇ�A�����Ƃ��Ȃ��B
        OR  xoha.deliver_from         =  gt_param.deliver_from               -- �p�����[�^�F�o�Ɍ���NULL�łȂ��ꍇ�A�����ɒǉ�
        OR  xil2v.distribution_block  =  gt_param.block)                     -- �p�����[�^�F�u���b�N��NULL�łȂ��ꍇ�A�����ɒǉ�
--Mod end 2008/07/18 H.Itou
      AND   TRUNC( xoha.schedule_ship_date )   = TRUNC( gt_param.date_from )  -- �p�����[�^�F�o�ɓ�
-- 2008/10/20 v1.5 ADD START
      AND   xoha.schedule_ship_date IS NOT NULL
-- 2008/10/20 v1.5 ADD END
      AND   xoha.latest_external_flag          = gc_latest_external_flag
      -------------------------------------------------------------------------------
      -- �󒍃^�C�v���VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.order_type_id                 = xott2v.transaction_type_id
      AND   xott2v.shipping_shikyu_class       = gc_shipping_shikyu_syukka    
                                                                          -- �o�׎x���敪'�o�׈˗�'
      AND   xott2v.order_category_code        <> gc_order_category_code       -- �ԕi
      AND   (gt_param.deliver_type IS NULL
             OR
             xott2v.transaction_type_id        = gt_param.deliver_type )
                                                                            -- �p�����[�^�F�o�Ɍ`��
      -------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      -------------------------------------------------------------------------------
      AND   xoha.order_header_id               = xola.order_header_id
      AND   xola.delete_flag                  <> gc_delete_flag
-- 2008/10/20 v1.5 DEL START
-- 2008/08/07 v1.4 ADD START
--      AND   xola.quantity                      > 0
-- 2008/08/07 v1.4 ADD END
-- 2008/10/20 v1.5 DEL END
      -------------------------------------------------------------------------------
      -- OPM�i�ڏ��VIEW2
      -------------------------------------------------------------------------------
      AND  xola.shipping_inventory_item_id     = xim2v.inventory_item_id
      AND xim2v.start_date_active             <= xoha.schedule_ship_date
      AND (
             (xim2v.end_date_active           >= xoha.schedule_ship_date)
          OR
             (xim2v.end_date_active IS NULL)
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM�i�ڃJ�e�S���������VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�i�ڃJ�e�S���������VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '���O�敪'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--           xic3v.item_class_code               = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
           xic5v.item_class_code               = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
--      AND xic3v.prod_class_code                = gt_param.prod_div         -- �p�����[�^�F���i�敪
      AND xic5v.prod_class_code                = gt_param.prod_div         -- �p�����[�^�F���i�敪
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- �ړ����b�g�ڍ�(�A�h�I��)
      -------------------------------------------------------------------------------
      AND   xola.order_line_id                 = xmld.mov_line_id(+)
      AND   xmld.document_type_code(+)         = gc_doc_type_code_syukka         -- �o�׈˗�
      AND   xmld.record_type_code(+)           = gc_rec_type_code_ins            -- �w��
      -------------------------------------------------------------------------------
      -- OPM���b�g�}�X�^
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                        = ilm.lot_id(+)
      AND   xmld.item_id                       = ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ���VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_from_id               = xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -- �ڋq�T�C�g���VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_to_id                 = xcas2v.party_site_id
      AND   xcas2v.start_date_active          <= xoha.schedule_ship_date
      AND   (
              xcas2v.end_date_active          >= xoha.schedule_ship_date
            OR
              xcas2v.end_date_active IS NULL
            )
      -------------------------------------------------------------------------------
      -- �N�C�b�N�R�[�h���VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--     AND xlv2v.lookup_code = xic3v.int_ext_class                  -- ���Б��Ћ敪(1:���ЁA2:���Ёj
      AND xlv2v.lookup_code = mcb.attribute1                       -- ���Б��Ћ敪(1:���ЁA2:���Ёj
-- 2008/10/20 1.5 ADD START �i��/���b�g�P�ʂɐ��ʂ����v
      GROUP BY
       xott2v.transaction_type_name    -- �o�Ɍ`��
        , xoha.order_type_id    
        ,xoha.deliver_from             -- �o�Ɍ�
        ,xil2v.description             -- �o�Ɍ�(����)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xoha.deliver_to)                 -- �z����/���ɐ�i�R�[�h�j
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xcas2v.party_site_full_name)       -- �z����/���ɐ�i���́j
        ,xic5v.item_class_name          -- �i�ڋ敪��
        ,xoha.schedule_ship_date        -- �o�ɓ�
        ,mcb.attribute1                 -- ���O�敪�i���Б��Ћ敪�R�[�h�j
        ,xlv2v.meaning                  -- ���O�敪
        ,xola.shipping_item_code        -- �i�ځi�R�[�h�j
        ,xim2v.item_short_name          -- �i�ځi���́j
        ,xim2v.conv_unit                -- ���o�Ɋ��Z�P��
        ,xmld.lot_no                    -- ���b�gNo
        ,ilm.attribute1                 -- ������
        ,ilm.attribute3                 -- �ܖ�����
        ,ilm.attribute2                 -- �ŗL�L��
        ,xic5v.item_class_code          -- �i�ڃN���X�R�[�h
        ,xim2v.num_of_cases             -- ����
        ,xim2v.item_um                  -- ���v��_�P��
-- 2008/10/20 1.5 ADD END
-- 2008/08/07 v1.4 UPDATE END
      ORDER BY
         xoha.order_type_id           ASC
        ,xoha.deliver_from            ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xola.shipping_item_code      ASC
        ,xmld.lot_no                  ASC
      ;
--
    CURSOR cur_shikyu_data
    IS
    SELECT
       xott2v.transaction_type_name         AS  trans_type        -- �o�Ɍ`��
      ,xoha.deliver_from                    AS  ship_cd           -- �o�Ɍ�
      ,xil2v.description                    AS  ship_nm           -- �o�Ɍ�(����)
--MOD START 2008/10/20 1.5 
--      ,xoha.vendor_site_code                AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
--      ,xvs2v.vendor_site_name               AS  delivery_to_nm    -- �z����/���ɐ�i���́j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xoha.vendor_site_code)             AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xvs2v.vendor_site_name)            AS  delivery_to_nm   -- �z����/���ɐ�i���́j
--MOD START 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- �i�ڋ敪��
      ,xic5v.item_class_name                AS  item_class        -- �i�ڋ敪��
-- 2008/08/07 v1.4 UPDATE END
      ,xoha.schedule_ship_date              AS  ship_date         -- �o�ɓ�
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
      ,mcb.attribute1                       AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                        AS  int_ext_class     -- ���O�敪
      ,xola.shipping_item_code              AS  item_cd           -- �i�ځi�R�[�h�j
      ,xim2v.item_short_name                AS  item_nm           -- �i�ځi���́j
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--      ,CASE                                     
--        -- ��������Ă���ꍇ
--        WHEN ( xola.reserved_quantity > 0 ) THEN
--            xmld.actual_quantity
--        -- ��������Ă��Ȃ��ꍇ
--        WHEN  ( ( xola.reserved_quantity IS NULL ) OR ( xola.reserved_quantity = 0 ) ) THEN
--            xola.quantity
--        END                                 AS  qty               -- ���v��
      ,CASE                                     
        -- ��������Ă���ꍇ
        WHEN ( SUM(xola.reserved_quantity) > 0 ) THEN
            SUM(xmld.actual_quantity)
        -- ��������Ă��Ȃ��ꍇ
        WHEN  ( ( SUM(xola.reserved_quantity) IS NULL ) OR ( SUM(xola.reserved_quantity) = 0 ) ) THEN
            SUM(xola.quantity)
        END                                 AS  qty               -- ���v��
-- 2008/10/20 1.5 MOD END
      ,xim2v.item_um                        AS  qty_tani          -- ���v��_�P��
      ,xmld.lot_no                          AS  lot_no            -- ���b�gNo
      ,ilm.attribute1                       AS  prod_date         -- ������
      ,ilm.attribute3                       AS  best_before_date  -- �ܖ�����
      ,ilm.attribute2                       AS  native_sign       -- �ŗL�L��
      ,xoha.order_type_id                   AS  trans_type_id     -- �o�Ɍ`�ԁiID�j
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
      ,xic5v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxwsh_order_headers_all                xoha       -- �󒍃w�b�_�A�h�I��
      ,xxwsh_oe_transaction_types2_v          xott2v     -- �󒍃^�C�v���VIEW2
      ,xxwsh_order_lines_all                  xola       -- �󒍖��׃A�h�I��
      ,xxcmn_item_mst2_v                      xim2v      -- OPM�i�ڏ��VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM�i�ڃJ�e�S���������VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM�i�ڃJ�e�S���������VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld       -- �ړ����b�g�ڍ�(�A�h�I��)
      ,ic_lots_mst                            ilm        -- OPM���b�g�}�X�^
      ,xxcmn_item_locations2_v                xil2v      -- OPM�ۊǏꏊ���VIEW2
      ,xxcmn_vendor_sites2_v                  xvs2v      -- �d����T�C�g���VIEW2
      ,xxcmn_lookup_values2_v                 xlv2v      -- �N�C�b�N�R�[�h���VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- �󒍃w�b�_�A�h�I��
      -------------------------------------------------------------------------------
            xoha.req_status                    >= gc_req_status_juryozumi  -- ��̍�
      AND   (gt_param.deliver_to IS NULL
             OR
             --Mod start 2008/06/24 uehara
--             xoha.deliver_to                    = gt_param.deliver_to )
             xoha.vendor_site_code                    = gt_param.deliver_to )
             --Mod end 2008/06/24 uehara
                                                                       -- �p�����[�^�F�z����/���ɐ�
      AND   xoha.req_status                    <> gc_req_status_torikeshi  -- ���
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xoha.deliver_from                = gt_param.deliver_from )  -- �p�����[�^�F�o�Ɍ�
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v.distribution_block         = gt_param.block )         -- �p�����[�^�F�u���b�N
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- �p�����[�^�F�o�Ɍ��A�p�����[�^�F�u���b�N��NULL�̏ꍇ�A�����Ƃ��Ȃ��B
        OR  xoha.deliver_from         =  gt_param.deliver_from               -- �p�����[�^�F�o�Ɍ���NULL�łȂ��ꍇ�A�����ɒǉ�
        OR  xil2v.distribution_block  =  gt_param.block)                     -- �p�����[�^�F�u���b�N��NULL�łȂ��ꍇ�A�����ɒǉ�
--Mod end 2008/07/18 H.Itou
      AND   xoha.schedule_ship_date             = gt_param.date_from       -- �p�����[�^�F�o�ɓ�
      AND   xoha.latest_external_flag           = gc_latest_external_flag
      -------------------------------------------------------------------------------
      -- �󒍃^�C�v���VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.order_type_id                  = xott2v.transaction_type_id
      AND   xott2v.shipping_shikyu_class        = gc_shipping_shikyu_shikyu
                                                                          -- �o�׎x���敪'�x���˗�'
      AND   xott2v.order_category_code         <> gc_order_category_code  -- �ԕi
      AND   (gt_param.deliver_type IS NULL
             OR
             xott2v.transaction_type_id         = gt_param.deliver_type )   -- �p�����[�^�F�o�Ɍ`��
      -------------------------------------------------------------------------------
      -- �󒍖��׃A�h�I��
      -------------------------------------------------------------------------------
      AND   xoha.order_header_id                = xola.order_header_id
      AND   xola.delete_flag                   <> gc_delete_flag
      -------------------------------------------------------------------------------
      -- OPM�i�ڏ��VIEW2
      -------------------------------------------------------------------------------
      AND  xola.shipping_inventory_item_id      = xim2v.inventory_item_id
      AND xim2v.start_date_active              <= xoha.schedule_ship_date
      AND (
             (xim2v.end_date_active            >= xoha.schedule_ship_date)
          OR
             (xim2v.end_date_active IS NULL)
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM�i�ڃJ�e�S���������VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�i�ڃJ�e�S���������VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '���O�敪'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--           xic3v.item_class_code               = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
           xic5v.item_class_code               = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
--      AND xic3v.prod_class_code                = gt_param.prod_div         -- �p�����[�^�F���i�敪
      AND xic5v.prod_class_code                = gt_param.prod_div         -- �p�����[�^�F���i�敪
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- �ړ����b�g�ڍ�(�A�h�I��)
      -------------------------------------------------------------------------------
      AND   xola.order_line_id                  = xmld.mov_line_id(+)
      AND   xmld.document_type_code(+)          = gc_doc_type_code_shikyu          -- �x���w��
      AND   xmld.record_type_code(+)            = gc_rec_type_code_ins             -- �w��
      -------------------------------------------------------------------------------
      -- OPM���b�g�}�X�^
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                         = ilm.lot_id(+)
      AND   xmld.item_id                        = ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ���VIEW2
      -------------------------------------------------------------------------------
      AND   xoha.deliver_from_id                = xil2v.inventory_location_id
      -------------------------------------------------------------------------------
      -- �d����T�C�g���VIEW2
      -------------------------------------------------------------------------------
      AND xoha.vendor_site_id                   = xvs2v.vendor_site_id
      AND xvs2v.start_date_active              <= xoha.schedule_ship_date
      AND (
             xvs2v.end_date_active             >= xoha.schedule_ship_date
          OR
             xvs2v.end_date_active IS NULL
          )
      -------------------------------------------------------------------------------
      -- �N�C�b�N�R�[�h���VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type                     = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--      AND xlv2v.lookup_code                     = xic3v.int_ext_class
      AND xlv2v.lookup_code                     = mcb.attribute1
-- 2008/08/07 v1.4 UPDATE END
                                                             -- ���Б��Ћ敪(1:���ЁA2:���Ёj
-- 2008/10/20 1.5 ADD START �i��/���b�g�P�ʂɐ��ʂ����v
      GROUP BY
        xott2v.transaction_type_name   -- �o�Ɍ`��
        ,xoha.deliver_from              -- �o�Ɍ�
        ,xil2v.description              -- �o�Ɍ�(����)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xoha.vendor_site_code)       -- �z����/���ɐ�i�R�[�h�j
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xvs2v.vendor_site_name)      -- �z����/���ɐ�i���́j
        ,xic5v.item_class_name          -- �i�ڋ敪��
        ,xoha.schedule_ship_date        -- �o�ɓ�
        ,mcb.attribute1                 -- ���O�敪�i���Б��Ћ敪�R�[�h�j
        ,xlv2v.meaning                  -- ���O�敪
        ,xola.shipping_item_code        -- �i�ځi�R�[�h�j
        ,xim2v.item_short_name          -- �i�ځi���́j
        ,xim2v.item_um                  -- ���v��_�P��
        ,xmld.lot_no                    -- ���b�gNo
        ,ilm.attribute1                 -- ������
        ,ilm.attribute3                 -- �ܖ�����
        ,ilm.attribute2                 -- �ŗL�L��
        ,xoha.order_type_id             -- �o�Ɍ`�ԁiID�j
        ,xic5v.item_class_code          -- �i�ڋ敪�R�[�h
-- 2008/10/20 1.5 ADD END
      ORDER BY
         xoha.order_type_id           ASC
        ,xoha.deliver_from            ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xola.shipping_item_code      ASC
        ,xmld.lot_no                  ASC
      ;
--
    CURSOR cur_move_data
    IS
    SELECT
       NULL                                AS  trans_type        -- �o�Ɍ`��
      ,xmrih.shipped_locat_code            AS  ship_cd           -- �o�Ɍ�
      ,xil2v1.description                  AS  ship_nm           -- �o�Ɍ�(����)
--MOD START 2008/10/20 1.5 
--      ,xmrih.ship_to_locat_code            AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
--      ,xil2v2.description                  AS  delivery_to_nm    -- �z����/���ɐ�i���́j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xmrih.ship_to_locat_code)         AS  delivery_to_cd    -- �z����/���ɐ�i�R�[�h�j
      ,DECODE(gt_param.deliver_to
        ,NULL,NULL
        ,xil2v2.description)               AS  delivery_to_nm   -- �z����/���ɐ�i���́j
--MOD END 2008/10/20 1.5 
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_name                AS  item_class        -- �i�ڋ敪��
      ,xic5v.item_class_name                AS  item_class        -- �i�ڋ敪��
-- 2008/08/07 v1.4 UPDATE END
      ,xmrih.schedule_ship_date            AS  ship_date         -- �o�ɓ�
-- 2008/08/07 v1.4 UPDATE START
--     ,xic3v.int_ext_class                  AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
      ,mcb.attribute1                       AS  in_out_class_code -- ���O�敪�i���Б��Ћ敪�R�[�h�j
-- 2008/08/07 v1.4 UPDATE END
      ,xlv2v.meaning                       AS  int_ext_class     -- ���O�敪
      ,xmril.item_code                     AS  item_cd           -- �i�ځi�R�[�h�j
      ,xim2v.item_short_name               AS  item_nm           -- �i�ځi���́j
-- 2008/10/20 1.5 MOD START �i��/���b�g�P�ʂɐ��ʂ����v
--      ,CASE
--        -- ��������Ă���ꍇ
--        WHEN ( xmril.reserved_quantity > 0 ) THEN
--          CASE 
---- 2008/08/07 v1.4 UPDATE START
----            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
--            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
---- 2008/08/07 v1.4 UPDATE END
--            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
--              xmld.actual_quantity / TO_NUMBER(
--                                                CASE
--                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
--                                                    xim2v.num_of_cases
--                                                  ELSE
--                                                    TO_CHAR(1)
--                                                END
--                                              )
--            ELSE
--              xmld.actual_quantity
--            END
--        -- ��������Ă��Ȃ��ꍇ
--        WHEN  ( ( xmril.reserved_quantity IS NULL ) OR ( xmril.reserved_quantity = 0 ) ) THEN
--          CASE 
---- 2008/08/07 v1.4 UPDATE START
----            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
--            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
---- 2008/08/07 v1.4 UPDATE END
--            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
--              xmril.instruct_qty / TO_NUMBER(
--                                        CASE
--                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
--                                            xim2v.num_of_cases
--                                          ELSE
--                                            TO_CHAR(1)
--                                        END
--                                       )
----            ELSE
----              xmril.instruct_qty
----            END
----        END                                AS  qty               -- ���v��      
      ,CASE
        -- ��������Ă���ꍇ
        WHEN ( SUM(xmril.reserved_quantity) > 0 ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
              SUM(xmld.actual_quantity) / TO_NUMBER(
                                                CASE
                                                  WHEN ( xim2v.num_of_cases > 0 ) THEN
                                                    xim2v.num_of_cases
                                                  ELSE
                                                    TO_CHAR(1)
                                                END
                                              )
            ELSE
              SUM(xmld.actual_quantity)
            END
        -- ��������Ă��Ȃ��ꍇ
        WHEN  ( ( SUM(xmril.reserved_quantity) IS NULL ) OR ( SUM(xmril.reserved_quantity) = 0 ) ) THEN
          CASE 
-- 2008/08/07 v1.4 UPDATE START
--            WHEN  ( ( xic3v.item_class_code = gc_item_cd_prdct )
            WHEN  ( ( xic5v.item_class_code = gc_item_cd_prdct )
-- 2008/08/07 v1.4 UPDATE END
            AND     ( xim2v.conv_unit IS NOT NULL  ) ) THEN
              SUM(xmril.instruct_qty) / TO_NUMBER(
                                        CASE
                                          WHEN ( xim2v.num_of_cases > 0 ) THEN
                                            xim2v.num_of_cases
                                          ELSE
                                            TO_CHAR(1)
                                        END
                                       )
            ELSE
              SUM(xmril.instruct_qty)
            END
        END                                AS  qty               -- ���v��
-- 2008/10/20 1.5 MOD END
      ,CASE
       -- �����@
-- 2008/08/07 v1.4 UPDATE START
--       WHEN (    xic3v.item_class_code = gc_item_cd_prdct
       WHEN (    xic5v.item_class_code = gc_item_cd_prdct
-- 2008/08/07 v1.4 UPDATE END
             AND xim2v.conv_unit IS NOT NULL) THEN
         xim2v.conv_unit
       ELSE
         -- �����A
         xim2v.item_um
       END                                 AS  qty_tani          -- ���v��_�P��
      ,xmld.lot_no                         AS  lot_no            -- ���b�gNo
      ,ilm.attribute1                      AS  prod_date         -- ������
      ,ilm.attribute3                      AS  best_before_date  -- �ܖ�����
      ,ilm.attribute2                      AS  native_sign       -- �ŗL�L��
      ,NULL                                AS  order_type_id     -- �o�Ɍ`��(ID)
-- 2008/08/07 v1.4 UPDATE START
--      ,xic3v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
      ,xic5v.item_class_code                AS  item_class_code   -- �i�ڋ敪�R�[�h
-- 2008/08/07 v1.4 UPDATE END
    FROM
       xxinv_mov_req_instr_headers            xmrih            -- �ړ��˗�/�w���w�b�_�A�h�I��
      ,xxinv_mov_req_instr_lines              xmril            -- �ړ��˗�/�w������(�A�h�I��)
      ,xxcmn_item_mst2_v                      xim2v            -- OPM�i�ڏ��VIEW2
-- 2008/08/07 v1.4 UPDATE START
--     ,xxcmn_item_categories3_v               xic3v                 -- OPM�i�ڃJ�e�S���������VIEW3
      ,xxcmn_item_categories5_v               xic5v                 -- OPM�i�ڃJ�e�S���������VIEW5
      ,gmi_item_categories                    gic
      ,mtl_categories_b                       mcb
      ,mtl_categories_tl                      mct
      ,mtl_category_sets_b                    mcsb
      ,mtl_category_sets_tl                   mcst
-- 2008/08/07 v1.4 UPDATE END
      ,xxinv_mov_lot_details                  xmld             -- �ړ����b�g�ڍ�(�A�h�I��)
      ,ic_lots_mst                            ilm              -- OPM���b�g�}�X�^
      ,xxcmn_item_locations2_v                xil2v1           -- OPM�ۊǏꏊ���VIEW2-1
      ,xxcmn_item_locations2_v                xil2v2           -- OPM�ۊǏꏊ���VIEW2-2
      ,xxcmn_lookup_values2_v                 xlv2v            -- �N�C�b�N�R�[�h���VIEW2
    WHERE
      -------------------------------------------------------------------------------
      -- �ړ��˗�/�w���w�b�_�A�h�I��
      -------------------------------------------------------------------------------
          xmrih.mov_type                       <> gc_mov_type_not_ship      -- �ϑ������łȂ�
      AND xmrih.status                         >= gc_status_reqed           -- �˗��ψȏ�
      AND xmrih.status                         <> gc_status_not             -- ������܂܂Ȃ�
      AND (gt_param.deliver_to IS NULL
           OR
           xmrih.ship_to_locat_code             = gt_param.deliver_to )
                                                                      -- �p�����[�^�F�z����/���ɐ�
--Mod start 2008/07/18 H.Itou
--      AND (
--             (gt_param.deliver_from IS NULL
--              OR
--              xmrih.shipped_locat_code          = gt_param.deliver_from )   -- �p�����[�^�F�o�Ɍ�
--          OR
--             (gt_param.block IS NULL
--              OR
--              xil2v1.distribution_block         = gt_param.block )          -- �p�����[�^�F�u���b�N
--          )
      AND  (((gt_param.deliver_from IS NULL) AND  (gt_param.block IS NULL))  -- �p�����[�^�F�o�Ɍ��A�p�����[�^�F�u���b�N��NULL�̏ꍇ�A�����Ƃ��Ȃ��B
        OR  xmrih.shipped_locat_code   =  gt_param.deliver_from               -- �p�����[�^�F�o�Ɍ���NULL�łȂ��ꍇ�A�����ɒǉ�
        OR  xil2v1.distribution_block  =  gt_param.block)                     -- �p�����[�^�F�u���b�N��NULL�łȂ��ꍇ�A�����ɒǉ�
--Mod end 2008/07/18 H.Itou
      AND xmrih.schedule_ship_date              = gt_param.date_from        -- �p�����[�^�F�o�ɓ�
--ADD START 2008/10/20 1.5 �w���Ȃ����т����O
      AND (xmrih.no_instr_actual_class IS NULL
        OR xmrih.no_instr_actual_class  <> gc_no_instr_actual_class)            -- �w���Ȃ����шȊO
--ADD END 2008/10/20 1.5
      -------------------------------------------------------------------------------
      -- �ړ��˗�/�w������(�A�h�I��)
      -------------------------------------------------------------------------------
      AND xmrih.mov_hdr_id                      =  xmril.mov_hdr_id
      AND xmril.delete_flg                     <>  gc_delete_flag
--DEL START 2008/10/20 1.5 �w���Ȃ����т����O
-- 2008/08/07 v1.4 ADD START
--      AND xmril.instruct_qty                    > 0
-- 2008/08/07 v1.4 ADD END
--DEL END 2008/10/20 1.5
      -------------------------------------------------------------------------------
      -- OPM�i�ڏ��VIEW2
      -------------------------------------------------------------------------------
      AND xmril.item_id                         =  xim2v.item_id
      AND xim2v.start_date_active              <=  xmrih.schedule_ship_date
      AND (
             xim2v.end_date_active IS NULL
          OR
             xim2v.end_date_active             >=  xmrih.schedule_ship_date
          )
-- 2008/08/07 v1.4 UPDATE START
--      -------------------------------------------------------------------------------
--      -- OPM�i�ڃJ�e�S���������VIEW3
--      -------------------------------------------------------------------------------
      -------------------------------------------------------------------------------
      -- OPM�i�ڃJ�e�S���������VIEW
      -------------------------------------------------------------------------------
--      AND xim2v.item_id                        = xic3v.item_id
      AND xim2v.item_id                        = xic5v.item_id
      AND mct.source_lang                      = 'JA'
      AND mct.language                         = 'JA'
      AND mcb.category_id                      = mct.category_id
      AND mcsb.structure_id                    = mcb.structure_id
      AND gic.category_id                      = mcb.category_id
      AND mcst.source_lang                     = 'JA'
      AND mcst.language                        = 'JA'
      AND mcst.category_set_name               = '���O�敪'
      AND mcsb.category_set_id                 = mcst.category_set_id
      AND gic.category_set_id                  = mcsb.category_set_id
      AND xim2v.item_id                        = gic.item_id
--     AND xic3v.prod_class_code                 = gt_param.prod_div         -- �p�����[�^�F���i�敪
      AND xic5v.prod_class_code                 = gt_param.prod_div         -- �p�����[�^�F���i�敪
-- 2008/08/07 v1.4 UPDATE END
      AND (gt_param.item_div IS NULL
           OR
-- 2008/08/07 v1.4 UPDATE START
--          xic3v.item_class_code                = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
           xic5v.item_class_code                = gt_param.item_div )       -- �p�����[�^�F�i�ڋ敪
-- 2008/08/07 v1.4 UPDATE END
      -------------------------------------------------------------------------------
      -- �ړ����b�g�ڍ�(�A�h�I��)
      -------------------------------------------------------------------------------
      AND xmril.mov_line_id                     = xmld.mov_line_id(+)
      AND xmld.document_type_code(+)            = gc_doc_type_code_mv       -- ���̓^�C�v�u�ړ��v
      AND xmld.record_type_code(+)              = gc_rec_type_code_ins    -- ���R�[�h�^�C�v�u�w���v
      -------------------------------------------------------------------------------
      -- OPM���b�g�}�X�^
      -------------------------------------------------------------------------------
      AND   xmld.lot_id                         =  ilm.lot_id(+)
      AND   xmld.item_id                        =  ilm.item_id(+)
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ���VIEW2-1
      -------------------------------------------------------------------------------
      AND xmrih.shipped_locat_id                =  xil2v1.inventory_location_id
      -------------------------------------------------------------------------------
      -- OPM�ۊǏꏊ���VIEW2-2
      -------------------------------------------------------------------------------
      AND xmrih.ship_to_locat_id                =  xil2v2.inventory_location_id
      -------------------------------------------------------------------------------
      -- �N�C�b�N�R�[�h���VIEW2
      -------------------------------------------------------------------------------
      AND xlv2v.lookup_type = gc_lookup_type_621b_int
-- 2008/08/07 v1.4 UPDATE START
--     AND xlv2v.lookup_code = xic3v.int_ext_class                  -- ���Б��Ћ敪(1:���ЁA2:���Ёj
      AND xlv2v.lookup_code = mcb.attribute1                       -- ���Б��Ћ敪(1:���ЁA2:���Ёj
-- 2008/10/20 1.5 ADD START �i��/���b�g�P�ʂɐ��ʂ����v
      GROUP BY
        xmrih.shipped_locat_code     -- �o�Ɍ�
        ,xil2v1.description          -- �o�Ɍ�(����)
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xmrih.ship_to_locat_code) -- �z����/���ɐ�i�R�[�h�j
        ,DECODE(gt_param.deliver_to
          ,NULL,NULL
          ,xil2v2.description)       -- �z����/���ɐ�i���́j
        ,xic5v.item_class_name       -- �i�ڋ敪��
        ,xmrih.schedule_ship_date    -- �o�ɓ�
        ,mcb.attribute1              -- ���O�敪�i���Б��Ћ敪�R�[�h�j
        ,xlv2v.meaning               -- ���O�敪
        ,xmril.item_code             -- �i�ځi�R�[�h�j
        ,xim2v.item_short_name       -- �i�ځi���́j
        ,xim2v.conv_unit             -- �P��
        ,xic5v.item_class_code       -- �i�ڋ敪�R�[�h
        ,xim2v.num_of_cases          -- ����
        ,xim2v.item_um               -- ���o�Ɋ��Z�P��
        ,xmld.lot_no                 -- ���b�gNo
        ,ilm.attribute1              -- ������
        ,ilm.attribute3              -- �ܖ�����
        ,ilm.attribute2              -- �ŗL�L��
        ,xic5v.item_class_code       -- �i�ڋ敪�R�[�h
-- 2008/10/20 1.5 ADD END
-- 2008/08/07 v1.4 UPDATE END
      ORDER BY
         xmrih.shipped_locat_code ASC
-- 2008/08/07 v1.4 UPDATE START
--        ,xic3v.item_class_code        ASC
--        ,xic3v.int_ext_class          ASC
        ,xic5v.item_class_code        ASC
        ,mcb.attribute1               ASC
-- 2008/08/07 v1.4 UPDATE END
        ,xmril.item_code          ASC
        ,xmld.lot_no              ASC
      ;
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
    -- �S���ҏ��擾
    -- ====================================================
    -- �S������
    gv_dept_cd := SUBSTRB(xxcmn_common_pkg.get_user_dept(FND_GLOBAL.USER_ID), 1, 10) ;
    -- �S����
    gv_dept_nm := SUBSTRB(xxcmn_common_pkg.get_user_name(FND_GLOBAL.USER_ID), 1, 14) ;
--
    -- ====================================================
    -- ���[�f�[�^�擾
    -- ====================================================
    -- �u�o�ׁv���w�肳�ꂽ�ꍇ
    IF (gt_param.business_typ = gc_biz_type_cd_ship) THEN
      gv_biz_kind := gc_biz_type_nm_ship ;
      -- �o�׈˗����擾
      OPEN cur_ship_data ;
      FETCH cur_ship_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_ship_data ;
    END IF;
--
    -- �u�x���v���w�肳�ꂽ�ꍇ
    IF (gt_param.business_typ = gc_biz_type_cd_shikyu) THEN
      gv_biz_kind := gc_biz_type_nm_shik ;
      -- �x���˗����擾
      OPEN cur_shikyu_data ;
      FETCH cur_shikyu_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_shikyu_data ;
    END IF;
--
    -- �u�ړ��v���w�肳�ꂽ�ꍇ
    IF (gt_param.business_typ = gc_biz_type_cd_move) THEN
      gv_biz_kind := gc_biz_type_nm_move ;
      -- �ړ��˗����擾
      OPEN cur_move_data ;
      FETCH cur_move_data BULK COLLECT INTO gt_report_data ;
      CLOSE cur_move_data ;
    END IF;
--
  EXCEPTION
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
  END prc_get_report_data;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : XML��������
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data(
    ov_errbuf     OUT  VARCHAR2     --   �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT  VARCHAR2     --   ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT  VARCHAR2     --   ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_create_xml_data' ;   -- �v���O������
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
    -- *** ���[�J���ϐ� ***
    -- �O�񃌃R�[�h�i�[�p
    lv_tmp_trans_type           type_report_data.trans_type_id%TYPE ;      -- �o�Ɍ`�Ԗ����
    lv_tmp_ship_cd              type_report_data.ship_cd%TYPE ;            -- �o�Ɍ������
    lv_tmp_item_class           type_report_data.item_class_code%TYPE ;    -- �i�ڋ敪�����
    -- �^�O�o�͔���t���O
    lb_dispflg_trans_type_cd    BOOLEAN := TRUE ;       -- �o�Ɍ`�Ԗ����
    lb_dispflg_ship_cd          BOOLEAN := TRUE ;       -- �o�Ɍ������
    lb_dispflg_item_class       BOOLEAN := TRUE ;       -- �i�ڋ敪�����
    lb_dispflg_dtl              BOOLEAN := TRUE ;       -- ���׏��
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2                 -- �^�O��
      ,ivsub_tag_value      IN  VARCHAR2                 -- �f�[�^
      ,ivsub_tag_type       IN  VARCHAR2  DEFAULT NULL   -- �f�[�^
    )IS
      ln_data_index  NUMBER ;    -- XML�f�[�^��ݒ肷��C���f�b�N�X
    BEGIN
      ln_data_index := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(ln_data_index).tag_name := ivsub_tag_name ;
      IF ((ivsub_tag_value IS NULL) AND (ivsub_tag_type = gc_tag_type_tag)) THEN
        -- �^�O�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_tag;
      ELSE
        -- �f�[�^�o��
        gt_xml_data_table(ln_data_index).tag_type := gc_tag_type_data;
        gt_xml_data_table(ln_data_index).tag_value := ivsub_tag_value;
      END IF;
    END prcsub_set_xml_data ;
--
    /**********************************************************************************
     * Procedure Name   : prcsub_set_xml_data
     * Description      : �^�O���ݒ菈��(�J�n�E�I���^�O�p)
     ***********************************************************************************/
    PROCEDURE prcsub_set_xml_data(
       ivsub_tag_name       IN  VARCHAR2  -- �^�O��
    )IS
    BEGIN
      prcsub_set_xml_data(ivsub_tag_name, NULL, gc_tag_type_tag);
    END prcsub_set_xml_data ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- -----------------------------------------------------
    -- �ϐ������ݒ�
    -- -----------------------------------------------------
    gt_xml_data_table.DELETE ;
    lv_tmp_trans_type := NULL ;
    lv_tmp_ship_cd    := NULL ;
    lv_tmp_item_class := NULL ;
--
    -- -----------------------------------------------------
    -- �w�b�_���ݒ�
    -- -----------------------------------------------------
    prcsub_set_xml_data('root') ;
    prcsub_set_xml_data('data_info') ;
    prcsub_set_xml_data('report_id', gc_report_id) ;
    prcsub_set_xml_data('exec_time', TO_CHAR(gd_common_sysdate, gc_date_fmt_all )) ;
    prcsub_set_xml_data('dep_cd'   , gv_dept_cd) ;
    prcsub_set_xml_data('dep_nm'   , gv_dept_nm) ;
    prcsub_set_xml_data('biz_kind' , gv_biz_kind) ;
    prcsub_set_xml_data('lg_trans_type_info') ;
--
    -- -----------------------------------------------------
    -- ���[0���pXML�f�[�^�쐬
    -- -----------------------------------------------------
    IF (gt_report_data.COUNT = 0) THEN
      ov_retcode := gv_status_warn ;
      ov_errmsg  := xxcmn_common_pkg.get_msg( gc_application_cmn, gc_msg_id_no_data ) ;
--
      prcsub_set_xml_data('g_trans_type_info') ;
      prcsub_set_xml_data('lg_ship_cd_info') ;
      prcsub_set_xml_data('g_ship_cd_info') ;
      prcsub_set_xml_data('lg_item_class_info') ;
      prcsub_set_xml_data('g_item_class_info') ;
      prcsub_set_xml_data('lg_ship_date_info') ;
      prcsub_set_xml_data('g_ship_date_info') ;
      prcsub_set_xml_data('msg' , ov_errmsg) ;
      prcsub_set_xml_data('/g_ship_date_info') ;
      prcsub_set_xml_data('/lg_ship_date_info') ;
      prcsub_set_xml_data('/g_item_class_info');
      prcsub_set_xml_data('/lg_item_class_info') ;
      prcsub_set_xml_data('/g_ship_cd_info') ;
      prcsub_set_xml_data('/lg_ship_cd_info');
      prcsub_set_xml_data('/g_trans_type_info') ;
    END IF ;
--
    -- -----------------------------------------------------
    -- XML�f�[�^�쐬
    -- -----------------------------------------------------
    <<detail_data_loop>>
    FOR i IN 1..gt_report_data.COUNT LOOP
--
      -- ====================================================
      -- XML�f�[�^�ݒ�
      -- ====================================================
--
      IF ( lb_dispflg_trans_type_cd OR lb_dispflg_ship_cd OR lb_dispflg_item_class ) THEN
        prcsub_set_xml_data('g_trans_type_info') ;
        prcsub_set_xml_data('trans_type'         , gt_report_data(i).trans_type ) ;
        prcsub_set_xml_data('lg_ship_cd_info') ;
        prcsub_set_xml_data('g_ship_cd_info') ;
        prcsub_set_xml_data('ship_cd', gt_report_data(i).ship_cd ) ;
        prcsub_set_xml_data('ship_nm', gt_report_data(i).ship_nm ) ;
        prcsub_set_xml_data('delivery_to_cd', gt_report_data(i).delivery_to_cd ) ;
        prcsub_set_xml_data('delivery_to_nm', gt_report_data(i).delivery_to_nm ) ;
        prcsub_set_xml_data('lg_item_class_info') ;
        prcsub_set_xml_data('g_item_class_info') ;
        prcsub_set_xml_data('item_class', gt_report_data(i).item_class ) ;
        prcsub_set_xml_data('lg_ship_date_info') ;
        prcsub_set_xml_data('g_ship_date_info') ;
        prcsub_set_xml_data('ship_date'
          , TO_CHAR(gt_report_data(i).ship_date, gc_date_fmt_ymd)) ;
        prcsub_set_xml_data('lg_dtl_info') ;
      END IF ;
--
      prcsub_set_xml_data('g_dtl_info') ;
      prcsub_set_xml_data('int_ext_class', gt_report_data(i).int_ext_class ) ;
      prcsub_set_xml_data('item_cd', gt_report_data(i).item_cd ) ;
      prcsub_set_xml_data('item_nm', gt_report_data(i).item_nm ) ;
      prcsub_set_xml_data('qty', gt_report_data(i).qty ) ;
      prcsub_set_xml_data('qty_tani', gt_report_data(i).qty_tani ) ;
      prcsub_set_xml_data('lot_no', gt_report_data(i).lot_no ) ;
      prcsub_set_xml_data('prod_date', gt_report_data(i).prod_date ) ;
      prcsub_set_xml_data('best_before_date', gt_report_data(i).best_before_date ) ;
      prcsub_set_xml_data('native_sign', gt_report_data(i).native_sign) ;
      prcsub_set_xml_data('/g_dtl_info') ;
--
      -- ====================================================
      -- ���ݏ������̃f�[�^��ێ�
      -- ====================================================
      lv_tmp_trans_type  := gt_report_data(i).trans_type_id ;
      lv_tmp_ship_cd     := gt_report_data(i).ship_cd ;
      lv_tmp_item_class  := gt_report_data(i).item_class_code ;
--
      -- ====================================================
      -- �o�͔���
      -- ====================================================
      IF (i < gt_report_data.COUNT) THEN
        -- �o�Ɍ`��
        IF ( NVL(lv_tmp_trans_type, 0) = NVL(gt_report_data(i+1).trans_type_id,0) ) THEN
          lb_dispflg_trans_type_cd := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
        END IF ;
--
        -- �o�Ɍ�
        IF ( NVL(lv_tmp_ship_cd, 0) = NVL(gt_report_data(i+1).ship_cd, 0) ) THEN
          lb_dispflg_ship_cd := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
        END IF ;
--
        -- �i�ڋ敪
        IF ( NVL(lv_tmp_item_class, 0) = NVL(gt_report_data(i+1).item_class_code, 0) ) THEN
          lb_dispflg_item_class := FALSE ;
        ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
          lb_dispflg_item_class    := TRUE ;
        END IF ;
--
      ELSE
          lb_dispflg_trans_type_cd := TRUE ;
          lb_dispflg_ship_cd       := TRUE ;
          lb_dispflg_item_class    := TRUE ;
      END IF;
--
      -- ====================================================
      -- �I���^�O�ݒ�
      -- ====================================================
--      
      IF ( lb_dispflg_item_class OR lb_dispflg_ship_cd OR lb_dispflg_trans_type_cd ) THEN
        prcsub_set_xml_data('/lg_dtl_info') ;
        prcsub_set_xml_data('/g_ship_date_info') ;
        prcsub_set_xml_data('/lg_ship_date_info') ;
        prcsub_set_xml_data('/g_item_class_info') ;
        prcsub_set_xml_data('/lg_item_class_info') ;
        prcsub_set_xml_data('/g_ship_cd_info') ;
        prcsub_set_xml_data('/lg_ship_cd_info') ;
        prcsub_set_xml_data('/g_trans_type_info') ;
      END IF;
    END LOOP detail_data_loop;
--
    -- ====================================================
    -- �I���^�O�ݒ�
    -- ====================================================
    prcsub_set_xml_data('/lg_trans_type_info') ;
    prcsub_set_xml_data('/data_info') ;
    prcsub_set_xml_data('/root') ;
--
  EXCEPTION
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
  END prc_create_xml_data;
--
  /**********************************************************************************
   * Function Name    : fnc_convert_into_xml
   * Description      : XML�f�[�^�ϊ�
   ***********************************************************************************/
  FUNCTION fnc_convert_into_xml(
    iv_name  IN VARCHAR2
   ,iv_value IN VARCHAR2
   ,ic_type  IN CHAR
  ) RETURN VARCHAR2
  IS
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_convert_data VARCHAR2(2000);
--
  BEGIN
--
    --�f�[�^�̏ꍇ
    IF (ic_type = 'D') THEN
      lv_convert_data := '<'||iv_name||'><![CDATA['||iv_value||']]></'||iv_name||'>';
    ELSE
      lv_convert_data := '<'||iv_name||'>';
    END IF ;
--
    RETURN(lv_convert_data);
--
  END fnc_convert_into_xml;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain(
    ov_errbuf     OUT   VARCHAR2      -- �G���[�E���b�Z�[�W           --# �Œ� #
   ,ov_retcode    OUT   VARCHAR2      -- ���^�[���E�R�[�h             --# �Œ� #
   ,ov_errmsg     OUT   VARCHAR2      -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
  )
  IS
--
--#####################  �Œ胍�[�J���萔�ϐ��錾�� START   ####################
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'submain' ;  -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    -- ===============================
    -- ���[�U�[�錾��
    -- ===============================
    -- *** ���[�J���ϐ� ***
    lv_xml_string    VARCHAR2(32000) ;
    ln_retcode       NUMBER ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ===============================================
    -- ��������
    -- ===============================================
    prc_initialize(
      ov_errbuf     => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    ) ;
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ===============================================
    -- ���[�f�[�^�擾����
    -- ===============================================
    prc_get_report_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML��������
    -- ==================================================
    prc_create_xml_data(
      ov_errbuf        => lv_errbuf       --�G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       => lv_retcode      --���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        => lv_errmsg       --���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ==================================================
    -- XML�o�͏���
    -- ==================================================
    -- XML�w�b�_���o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
--
    -- XML�f�[�^���o��
    <<xml_loop>>
    FOR i IN 1 .. gt_xml_data_table.COUNT LOOP
      lv_xml_string := fnc_convert_into_xml(
                         gt_xml_data_table(i).tag_name
                        ,gt_xml_data_table(i).tag_value
                        ,gt_xml_data_table(i).tag_type
                       ) ;
      -- XML�f�[�^�o��
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lv_xml_string) ;
    END LOOP xml_loop ;
--
    --XML�f�[�^�폜
    gt_xml_data_table.DELETE ;
--
    IF ((lv_retcode = gv_status_warn) AND (gt_report_data.COUNT = 0)) THEN
      RAISE no_data_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���[0����O�n���h�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := lv_errmsg ;
      ov_retcode := gv_status_warn;
--
--#################################  �Œ��O������ START   ###################################
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
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
--####################################  �Œ蕔 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                  OUT    VARCHAR2       -- �G���[�E���b�Z�[�W  --# �Œ� #
   ,retcode                 OUT    VARCHAR2       -- ���^�[���E�R�[�h    --# �Œ� #
   ,iv_biz_type             IN     VARCHAR2       -- 01 : �Ɩ����
   ,iv_deliver_type         IN     VARCHAR2       -- 02 : �o�Ɍ`��
   ,iv_block                IN     VARCHAR2       -- 03 : �u���b�N
   ,iv_deliver_from         IN     VARCHAR2       -- 04 : �o�Ɍ�
   ,iv_deliver_to           IN     VARCHAR2       -- 05 : �z����^���ɐ�
   ,iv_prod_div             IN     VARCHAR2       -- 06 : ���i�敪
   ,iv_item_div             IN     VARCHAR2       -- 07 : �i�ڋ敪
   ,iv_date                 IN     VARCHAR2       -- 08 : �o�ɓ�
  )
--
--###########################  �Œ蕔 START   ###########################
--
  IS
--
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'main' ; -- �v���O������
    -- ===============================
    -- ���[�J���ϐ�
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
  BEGIN
--
--###########################  �Œ蕔 END   #############################
--
    -- ===============================================
    -- �ϐ������ݒ�
    -- ===============================================
    -- ���̓p�����[�^���O���[�o���ϐ��ɕێ�
    gt_param.business_typ  := iv_biz_type ;                 -- 01 : �Ɩ����
    gt_param.deliver_type  := TO_NUMBER( iv_deliver_type ) ;  -- 02 : �o�Ɍ`��
    gt_param.block         := iv_block ;                    -- 03 : �u���b�N
    gt_param.deliver_from  := iv_deliver_from ;             -- 04 : �o�Ɍ�
    gt_param.deliver_to    := iv_deliver_to ;               -- 05 : �z����^���ɐ�
    gt_param.prod_div      := iv_prod_div ;                 -- 06 : ���i�敪
    gt_param.item_div      := iv_item_div ;                 -- 07 : �i�ڋ敪
    gt_param.date_from
              := FND_DATE.STRING_TO_DATE(iv_date, gc_date_fmt_ymd) ;
                                                      -- 08 : �o�ɓ�
--
    -- ===============================================
    -- submain�̌Ăяo���i���ۂ̏�����submain�ōs���j
    -- ===============================================
    submain(
      ov_errbuf    => lv_errbuf       -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode   => lv_retcode      -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg    => lv_errmsg       -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    );
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================
    IF ( lv_retcode = gv_status_error ) THEN
      errbuf := lv_errmsg ;
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    ELSIF ( lv_retcode = gv_status_warn ) THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, lv_errbuf) ;
--
    END IF ;
--
    --�X�e�[�^�X�Z�b�g
    retcode := lv_retcode ;
--
  EXCEPTION
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part|| SQLERRM ;
      retcode := gv_status_error ;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      errbuf  := gv_pkg_name || gv_msg_cont || cv_prg_name || gv_msg_part || SQLERRM ;
      retcode := gv_status_error ;
  END main;
--
--###########################  �Œ蕔 END   #######################################################
--
END xxwsh620004c;
/
