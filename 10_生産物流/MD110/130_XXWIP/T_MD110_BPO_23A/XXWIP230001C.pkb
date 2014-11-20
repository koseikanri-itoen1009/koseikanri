create or replace
PACKAGE BODY xxwip230001c
AS
/*****************************************************************************************
 * Copyright(c)Oracle Corporation Japan, 2007,2008. All rights reserved.
 *
 * Package Name     : xxwip230001c(body)
 * Description      : ���Y���[�@�\�i���Y�˗��������Y�w�}���j
 * MD.050/070       : ���Y���[�@�\�i���Y�˗��������Y�w�}���jIssue1.0  (T_MD050_BPO_230)
 *                    ���Y���[�@�\�i���Y�˗��������Y�w�}���j          (T_MD070_BPO_23A)
 * Version          : 1.9
 *
 * Program List
 * ---------------------------- ----------------------------------------------------------
 *  Name                         Description
 * ---------------------------- ----------------------------------------------------------
 *  fnc_conv_xml                 FUNCTION  : �w�l�k�^�O�ɕϊ�����B
 *  prc_out_xml_data             PROCEDURE : �^�O���o�͏���
 *  prc_create_xml_data          PROCEDURE : �w�l�k�^�O���ݒ菈��
 *  prc_get_sizai_data           PROCEDURE : ���ׁi���ށj���擾����
 *  prc_get_mei_title_data       PROCEDURE : ���׃^�C�g���擾����
 *  prc_get_tonyu_utikomi_data   PROCEDURE : ���ׁi�����E�ō��j���擾����
 *  prc_get_busho_data           PROCEDURE : �������擾����
 *  prc_get_head_data            PROCEDURE : �w�b�_�[���擾����
 *  prc_get_head_data            PROCEDURE : �p�����[�^�`�F�b�N����
 *  submain                      PROCEDURE : ���C�������v���V�[�W��
 *  main                         PROCEDURE : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ------------------- -------------------------------------------------
 *  Date          Ver.  Editor              Description
 * ------------- ----- ------------------- -------------------------------------------------
 *  2007/12/13    1.0   Masakazu Yamashita  �V�K�쐬
 *  2008/05/20    1.1   Yusuke   Tabata     �����ύX�v��Seq95(���t�^�p�����[�^�^�ϊ�)�Ή�
 *  2008/05/20    1.2   Daisuke  Nihei      �����e�X�g�s��Ή��i���ށF�˗������\������Ȃ��j
 *  2008/05/30    1.3   Daisuke  Nihei      �����e�X�g�s��Ή��i�����F�\��敪�s��)
 *  2008/06/04    1.4   Daisuke  Nihei      �����e�X�g�s��Ή��i���Y�w�����\���s��)
 *  2008/07/02    1.5   Satoshi  Yunba      �֑������Ή�
 *  2008/07/18    1.6   Hitomi   Itou       �����e�X�g �w�E23�Ή� ���Y�˗����̎��A�ۗ����E��z�ς��ΏۂƂ���
 *  2008/10/28    1.7   Daisuke  Nihei      ������Q#183�Ή� ���͓����̌�������쐬������X�V���ɕύX����
 *                                          ������Q#196�Ή� ��x�������ĂĂ���i�ڂ̃f�t�H���g���b�g��\�����Ȃ�
 *                                          T_TE080_BPO_230 No15�Ή� ���Y�w�}���̎��A��z�ς��ΏۂƂ���
 *                                          ������Q#499�Ή� �������A�݌ɓ����̎Q�Ɛ�ύX
 *  2009/01/16    1.8   Daisuke  Nihei      �{�ԏ�Q#1032�Ή� ���Y�w�}�����u�m��ρv�ł��o�͂���
 *  2009/02/02    1.9   Daisuke  Nihei      �{�ԏ�Q#1111�Ή�
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
  gv_pkg_name                   CONSTANT VARCHAR2(20) := 'XXWIP230001' ;                       -- �p�b�P�[�W��
  gc_report_id                  CONSTANT VARCHAR2(12) := 'XXWIP230001T' ;                      -- ���[ID
--
  -- �Ɩ��X�e�[�^�X
-- 2008/07/18 H.Itou ADD START
  gv_status_horyu               CONSTANT VARCHAR2(10) := '1';                                  -- �ۗ���
  gv_status_tehai_zumi          CONSTANT VARCHAR2(10) := '3';                                  -- ��z��
  gv_status_kanryou             CONSTANT VARCHAR2(10) := '7';                                  -- ����
  gv_status_close               CONSTANT VARCHAR2(10) := '8';                                  -- �N���[�Y
  gv_status_cancel              CONSTANT VARCHAR2(10) := '-1';                                 -- ���
-- 2008/07/18 H.Itou ADD END
  gv_status_irai_zumi           CONSTANT VARCHAR2(10) := '2';                                  -- �˗���
  gv_status_kakunin_zumi        CONSTANT VARCHAR2(10) := '5';                                  -- �m�F��
  gv_status_sasizu_zumi         CONSTANT VARCHAR2(10) := '4';                                  -- �w�}��
  gv_status_uketuke_zumi        CONSTANT VARCHAR2(10) := '6';                                  -- ��t��
--
  -- �i�ڋ敪
  gv_hinmoku_kbn_genryou        CONSTANT VARCHAR2(10) := '1';                                  -- ����
  gv_hinmoku_kbn_sizai          CONSTANT VARCHAR2(10) := '2';                                  -- ����
  gv_hinmoku_kbn_hanseihin      CONSTANT VARCHAR2(10) := '4';                                  -- �����i
  gv_hinmoku_kbn_seihin         CONSTANT VARCHAR2(10) := '5';                                  -- ���i
  gv_chohyo_title_irai          CONSTANT VARCHAR2(10) := '���Y�˗���';                         -- ���Y�˗���
  gv_chohyo_title_sasizu        CONSTANT VARCHAR2(10) := '���Y�w�}��';                         -- ���Y�w�}��
  gv_chohyo_kbn_irai            CONSTANT VARCHAR2(10) := '1';
  gv_chohyo_kbn_sasizu          CONSTANT VARCHAR2(10) := '2';
  gv_date_format1               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI:SS';              -- ���t�t�H�[�}�b�g
  gv_date_format2               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD HH24:MI';                 -- ���t�t�H�[�}�b�g
  gv_date_format3               CONSTANT VARCHAR2(50) := 'YYYY/MM/DD';                         -- ���t�t�H�[�}�b�g
  gv_line_type_kbn_genryou      CONSTANT VARCHAR2(10) := '-1';
  gv_line_type_kbn_seizouhin    CONSTANT VARCHAR2(10) := '1';
  gv_tonyu_title                CONSTANT VARCHAR2(50) := '���@��';
  gv_utikomi_title              CONSTANT VARCHAR2(50) := '���Ł@����';
  gv_sizai_title                CONSTANT VARCHAR2(50) := '���������ށ�';
  gv_utikomi_kbn_utikomi        CONSTANT VARCHAR2(1)  := 'Y';
  gv_seizouhin_kbn_drink        CONSTANT VARCHAR2(1)  := '3';
  gv_yotei_kbn_mov              CONSTANT VARCHAR2(1)  := '1';                                      -- �\��敪�i�ړ��j
  gv_yotei_kbn_tonyu            CONSTANT VARCHAR2(1)  := '4';                                      -- �\��敪�i�����j
  gv_ontyu                      CONSTANT VARCHAR2(10) := '�䒆';
--
  gv_err_input_date_from        CONSTANT VARCHAR2(20) := '���͓����iFROM�j';                       -- ���͓����iFROM�j
  gv_err_input_date_to          CONSTANT VARCHAR2(20) := '���͓����iTO�j';                         -- ���͓����iTO�j
  gv_err_make_plan_from         CONSTANT VARCHAR2(20) := '���Y�\����iFROM�j';                     -- ���Y�\����iFROM�j
  gv_err_make_plan_to           CONSTANT VARCHAR2(20) := '���Y�\����iTO�j';                       -- ���Y�\����iTO�j
  gv_err_mei_title_no_data      CONSTANT VARCHAR2(100) := '���������̂��擾�ł��܂���ł����B';
  gc_application_cmn            CONSTANT VARCHAR2(5)  := 'XXCMN' ;                                 -- �A�v���P�[�V�����iXXCMN�j
  gc_application_wip            CONSTANT VARCHAR2(5)  := 'XXWIP' ;                                 -- �A�v���P�[�V�����iXXWIP�j
  gv_tkn_date                   CONSTANT VARCHAR2(100) := 'DATE';                                  -- �g�[�N���FDATE
  gv_tkn_param1                 CONSTANT VARCHAR2(100) := 'PARAM1';                                -- �g�[�N���FPARAM1
  gv_tkn_param2                 CONSTANT VARCHAR2(100) := 'PARAM2';                                -- �g�[�N���FPARAM2
  gv_tkn_item                   CONSTANT VARCHAR2(100) := 'ITEM';                                  -- �g�[�N���FITEM
  gv_tkn_value                  CONSTANT VARCHAR2(100) := 'VALUE';                                 -- �g�[�N���FVALUE
-- 2008/10/28 v1.7 D.Nihei ADD START ������Q#499
  gv_doc_type_prod              CONSTANT VARCHAR2(4)   := 'PROD';                                  -- PROD (���Y)
-- 2008/10/28 v1.7 D.Nihei ADD END
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���^
  -- ===============================
--
  -- ���̓p�����[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_param_data IS RECORD 
    (
      iv_den_kbn          gmd_routings_vl.attribute13%TYPE              -- �`�[�敪
     ,iv_chohyo_kbn       VARCHAR2(1)                                   -- ���[�敪
     ,iv_plant            gme_batch_header.plant_code%TYPE              -- �v�����g�R�[�h
     ,iv_line_no          gmd_routings_vl.routing_no%TYPE               -- ���C��No
     ,id_make_plan_from   gme_batch_header.plan_start_date%TYPE         -- ���Y�\���(FROM)
     ,id_make_plan_to     gme_batch_header.plan_start_date%TYPE         -- ���Y�\���(TO)
     ,id_tehai_no_from    gme_batch_header.batch_no%TYPE                -- ��zNo(FROM)
     ,id_tehai_no_to      gme_batch_header.batch_no%TYPE                -- ��zNo(TO)
     ,iv_hinmoku_cd       xxcmn_item_mst2_v.item_no%TYPE                -- �i�ڃR�[�h
-- 2008/10/28 v1.7 D.Nihei MOD START
--     ,id_input_date_from  gme_batch_header.creation_date%TYPE           -- ���͓���(FROM)
--     ,id_input_date_to    gme_batch_header.creation_date%TYPE           -- ���͓���(TO)
     ,id_input_date_from  gme_batch_header.last_update_date%TYPE           -- ���͓���(FROM)
     ,id_input_date_to    gme_batch_header.last_update_date%TYPE           -- ���͓���(TO)
-- 2008/10/28 v1.7 D.Nihei MOD END
    ) ;
--
  -- �w�b�_�[�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_head_data_type_dtl IS RECORD 
    (
      l_itaku_saki        sy_orgn_mst_vl.orgn_name%TYPE                 -- �ϑ���
     ,l_tehai_no          gme_batch_header.batch_no%TYPE                -- ��zno
     ,l_den_kbn           xxcmn_lookup_values_v.meaning%TYPE            -- �`�[�敪
     ,l_kanri_bsho        xxcmn_lookup_values_v.meaning%TYPE            -- ���ъǗ�����
     ,l_item_cd           xxcmn_item_mst2_v.item_no%TYPE                -- �i�ڃR�[�h
     ,l_item_nm           xxcmn_item_mst2_v.item_short_name%TYPE        -- �i�ږ���
     ,l_line_no           gmd_routings_vl.routing_no%TYPE               -- ���C��no
     ,l_line_nm           gmd_routings_vl.routing_desc%TYPE             -- ���C������
     ,l_set_cd            gmd_routings_vl.attribute9%TYPE               -- �[�i�ꏊ�R�[�h
     ,l_set_nm            xxcmn_item_locations_v.description%TYPE       -- �[�i�ꏊ����
     ,l_make_plan         gme_batch_header.plan_start_date%TYPE         -- ���Y�\���
     ,l_stock_plan        gme_material_details.attribute22%TYPE         -- �������ɗ\���
     ,l_type              xxcmn_lookup_values_v.meaning%TYPE            -- �^�C�v
     ,l_rank1             gme_material_details.attribute2%TYPE          -- �����N�P
     ,l_rank2             gme_material_details.attribute3%TYPE          -- �����N�Q
     ,l_description       gme_material_details.attribute4%TYPE          -- �E�v
     ,l_lot_no            ic_lots_mst.lot_no%TYPE                       -- ���b�gno
     ,l_move_place_cd     gme_material_details.attribute12%TYPE         -- �ړ��ꏊ�R�[�h
     ,l_move_place_nm     xxcmn_item_locations_v.description%TYPE       -- �ړ��ꏊ����
     ,l_irai_total        gme_material_details.attribute7%TYPE          -- �˗�����
     ,l_plan_qty          gme_material_details.plan_qty%TYPE            -- �v�搔
-- 2009/02/02 v1.9 D.Nihei ADD START
     ,l_inst_qty          gme_material_details.attribute23%TYPE         -- �w�}����
-- 2009/02/02 v1.9 D.Nihei ADD END
     ,l_seizouhin_kbn     gmd_routings_vl.attribute16%TYPE              -- �����i�敪
     ,l_batch_id          gme_batch_header.batch_id%TYPE                -- �o�b�`ID
     ,l_last_updated_user gme_batch_header.last_updated_by%TYPE         -- �ŏI�X�V��
     ,l_item_id           xxcmn_item_mst2_v.item_id%TYPE                -- �i��ID
    ) ;
  TYPE tab_head_data_type_dtl IS TABLE OF rec_head_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ���ׁi�����E�ō��j�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_tonyu_utikmi_type_dtl IS RECORD 
    (
      l_item_cd               xxcmn_item_mst2_v.item_no%TYPE                -- �i�ڃR�[�h
     ,l_item_nm               xxcmn_item_mst2_v.item_short_name%TYPE        -- �i�ږ���
     ,l_lot_no                ic_lots_mst.lot_no%TYPE                       -- ���b�gno
     ,l_monve_no              xxwip_material_detail.plan_number%TYPE        -- �ړ��ԍ�
     ,l_souko                 xxwip_material_detail.location_code%TYPE      -- �q��
-- 2008/10/28 v1.7 D.Nihei MOD START ������Q#499
--     ,l_make_date             gme_material_details.attribute11%TYPE         -- ������
--     ,l_stock                 gme_material_details.attribute6%TYPE          -- �݌ɓ���
     ,l_make_date             ic_lots_mst.attribute1%TYPE                   -- ������
     ,l_stock                 ic_lots_mst.attribute6%TYPE                   -- �݌ɓ���
-- 2008/10/28 v1.7 D.Nihei MOD END
     ,l_total                 ic_tran_pnd.trans_qty%TYPE                    -- ����
     ,l_unit                  ic_tran_pnd.trans_um%TYPE                     -- �P��
     ,l_material_detail_id    gme_material_details.material_detail_id%TYPE  -- ���Y�����ڍ�ID
     ,l_shinkansen_kbn        gmd_routings_vl.attribute17%TYPE              -- �V�ʐ��敪
    ) ;
  TYPE tab_tonyu_utikomi_type_dtl IS TABLE OF rec_tonyu_utikmi_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- ���ׁi���ށj�f�[�^�i�[�p���R�[�h�ϐ�
  TYPE rec_sizai_data_type_dtl IS RECORD 
    (
      l_item_cd               xxcmn_item_mst2_v.item_no%TYPE                -- �i�ڃR�[�h
     ,l_item_nm               xxcmn_item_mst2_v.item_short_name%TYPE        -- �i�ږ���
-- 2008/10/28 v1.7 D.Nihei MOD START ������Q#499
--     ,l_stock                 gme_material_details.attribute6%TYPE          -- �݌ɓ���
     ,l_stock                 ic_lots_mst.attribute6%TYPE                   -- �݌ɓ���
-- 2008/10/28 v1.7 D.Nihei MOD END
     ,l_total                 xxwip_material_detail.instructions_qty%TYPE   -- ����
     ,l_unit                  xxcmn_item_mst2_v.item_um%TYPE                -- �P��
    ) ;
  TYPE tab_sizai_data_type_dtl IS TABLE OF rec_sizai_data_type_dtl INDEX BY BINARY_INTEGER ;
--
  -- �������i�[�p���R�[�h�ϐ�
  TYPE rec_busho_data  IS RECORD 
    (
      yubin_no   xxcmn_locations_all.zip%TYPE       -- �X�֔ԍ�
     ,address    xxcmn_locations_all.address_line1%TYPE     -- �Z��
     ,tel        xxcmn_locations_all.phone%TYPE             -- �d�b�ԍ�
     ,fax        xxcmn_locations_all.fax%TYPE               -- FAX�ԍ�
     ,busho_nm   xxcmn_locations_all.location_name%TYPE     -- ��������
    ) ;
--
  -- *** ���[�J���ϐ� ***
--
  -- ===============================
  -- ���[�U�[��`�O���[�o���ϐ�
  -- ===============================
  ------------------------------
  -- �w�l�k�p
  ------------------------------
  gt_xml_data_table         XML_DATA ;                -- �w�l�k�f�[�^�^�O�\
  gl_xml_idx                NUMBER ;                  -- �w�l�k�f�[�^�^�O�\�̃C���f�b�N�X
--
--#####################  �Œ苤�ʗ�O�錾�� START   ####################
--
  --*** ���������ʗ�O ***
  global_process_expt       EXCEPTION ;
  --*** ���ʊ֐���O ***
  global_api_expt           EXCEPTION ;
  --*** ���ʊ֐�OTHERS��O ***
  global_api_others_expt    EXCEPTION ;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000) ;
--
--###########################  �Œ蕔 END   ############################
--
  /**********************************************************************************
   * Function Name    : fnc_conv_xml
   * Description      : �w�l�k�^�O�ɕϊ�����B
   ***********************************************************************************/
  FUNCTION fnc_conv_xml
    (
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
   * Procedure Name   : prc_out_xml_data
   * Description      : �w�l�k�o�͏���
   ***********************************************************************************/
  PROCEDURE prc_out_xml_data
    (
      ov_errbuf     OUT VARCHAR2                  --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                  --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                  --    ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_out_xml_data'; -- �v���O������
--
--#####################  �Œ胍�[�J���ϐ��錾�� START   ########################
--
    lv_errbuf  VARCHAR2(5000);  -- �G���[�E���b�Z�[�W
    lv_retcode VARCHAR2(1);     -- ���^�[���E�R�[�h
    lv_errmsg  VARCHAR2(5000);  -- ���[�U�[�E�G���[�E���b�Z�[�W
--
--###########################  �Œ蕔 END   ####################################
--
    lv_xml_string           VARCHAR2(32000) ;
--
  BEGIN
--
--##################  �Œ�X�e�[�^�X�������� START   ###################
--
    ov_retcode := gv_status_normal;
--
--###########################  �Œ蕔 END   ############################
--
    -- ==================================================
    -- �w�l�k�o�͏���
    -- ==================================================
    -- �J�n�^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<?xml version="1.0" encoding="shift_jis" ?>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<root>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '<lg_irai_info>' ) ;
--
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
    -- �I���^�O�o��
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</lg_irai_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</data_info>' ) ;
    FND_FILE.PUT_LINE( FND_FILE.OUTPUT, '</root>' ) ;
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
  END prc_out_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_busho_data
   * Description      : �������擾
   ***********************************************************************************/
  PROCEDURE prc_get_busho_data
    (
      iv_last_updated_user   IN  gme_batch_header.last_updated_by%TYPE           -- �ŏI�X�V��
     ,or_busho_data     OUT rec_busho_data
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_busho_data'; -- �v���O������
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
    lv_busho_cd hr_locations_all.location_code%TYPE;            -- �����R�[�h
-- 
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_busho_data
      (
        iv_last_updated_user gme_batch_header.last_updated_by%TYPE
      )
    IS
      SELECT hla.location_code
      FROM fnd_user              fu
          ,per_all_assignments_f paaf
          ,hr_locations_all      hla
      WHERE fu.user_id           = iv_last_updated_user
      AND   fu.employee_id             = paaf.person_id
      AND   paaf.location_id           = hla.location_id
      AND   paaf.effective_start_date <= TRUNC(SYSDATE)
      AND   ((paaf.effective_end_date IS NULL) OR (paaf.effective_end_date   >= TRUNC(SYSDATE)))
      AND   fu.start_date             <= TRUNC(SYSDATE)
      AND   ((fu.end_date is NULL) OR (fu.end_date >= TRUNC(SYSDATE)))
      AND   hla.inactive_date           IS NULL
      AND   paaf.primary_flag = 'Y'
      
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
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_busho_data
      (
        iv_last_updated_user
      ) ;
    -- �t�F�b�`
    FETCH cur_busho_data INTO lv_busho_cd;
    -- �J�[�\���N���[�Y
    CLOSE cur_busho_data ;
--
    IF (lv_busho_cd IS NOT NULL) THEN
      -- =====================================================
      -- �������擾�v���V�[�W���Ăяo��
      -- =====================================================
      xxcmn_common_pkg.get_dept_info
        (
          iv_dept_cd                =>    lv_busho_cd
         ,id_appl_date              =>    NULL
         ,ov_postal_code            =>    or_busho_data.yubin_no
         ,ov_address                =>    or_busho_data.address
         ,ov_tel_num                =>    or_busho_data.tel
         ,ov_fax_num                =>    or_busho_data.fax
         ,ov_dept_formal_name       =>    or_busho_data.busho_nm
         ,ov_errbuf                 =>    lv_errbuf
         ,ov_retcode                =>    lv_retcode
         ,ov_errmsg                 =>    lv_errmsg
        );
--
    END IF;
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
  EXCEPTION
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_busho_data%ISOPEN THEN
        CLOSE cur_busho_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_busho_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_mei_title_data
   * Description      : �������׃^�C�g���擾
   ***********************************************************************************/
  PROCEDURE prc_get_mei_title_data
    (
      iv_material_detail_id IN VARCHAR2              -- ���Y�����ڍ�ID
     ,ov_mei_title          OUT VARCHAR2             -- ���׃^�C�g��
     ,ov_errbuf             OUT VARCHAR2             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode            OUT VARCHAR2             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg             OUT VARCHAR2             -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_mei_title_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_mei_title_data
      (
        iv_material_detail_id gme_material_details.material_detail_id%TYPE
      )
    IS
      SELECT gov.oprn_desc
      FROM   gme_batch_steps           gbs,           -- ���Y�o�b�`�X�e�b�v
             gmd_operations_vl         gov,           -- �H���}�X�^�r���[
             gme_batch_step_items      gbsi           -- ���Y�o�b�`�X�e�b�v�i��
      WHERE  gbs.batchstep_id        = gbsi.batchstep_id
      AND    gov.oprn_id             = gbs.oprn_id
      AND    gbsi.material_detail_id = iv_material_detail_id
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
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_mei_title_data
      (
        iv_material_detail_id
      ) ;
    -- �t�F�b�`
    FETCH cur_mei_title_data INTO ov_mei_title ;
    -- �J�[�\���N���[�Y
    CLOSE cur_mei_title_data ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_mei_title_data%ISOPEN THEN
        CLOSE cur_mei_title_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_mei_title_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_xml_data
   * Description      : �w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_xml_data
    (
      ir_param          IN  rec_param_data    -- 01.���R�[�h  �F�p�����[�^
     ,in_head_index     IN  NUMBER
     ,it_head_data      IN  tab_head_data_type_dtl
     ,it_tonyu_data     IN  tab_tonyu_utikomi_type_dtl
     ,it_utikomi_data   IN  tab_tonyu_utikomi_type_dtl
     ,it_sizai_data     IN  tab_sizai_data_type_dtl
     ,id_now_date       IN  DATE
     ,ov_errbuf         OUT VARCHAR2          --    �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          --    ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          --    ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    -- ���[�^�C�g��
    lv_chohyo_title           VARCHAR2(10) DEFAULT NULL;
    -- ���׃^�C�g��
    lv_mei_title              VARCHAR2(20) DEFAULT NULL;
    -- ���׃^�C�g���u���[�N�p
    lv_break_mei_title        VARCHAR2(20) DEFAULT '*';
    -- �������
    lr_busho_data             rec_busho_data;
    -- �P�[�X�����v�ZFunction�ߒl
    ln_return_num             NUMBER DEFAULT 0;
    -- �ϑ���
    lv_itaku_saki             VARCHAR2(100) DEFAULT NULL;
    -- �w�}����
    ln_sasizu_total           NUMBER DEFAULT 0;
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id     gme_material_details.material_detail_id%TYPE;  -- �ޔ�p���Y�����ڍ�ID
-- 2008/10/28 v1.7 D.Nihei ADD END
--
    -- *** ���[�J���E��O���� ***
    no_data_expt            EXCEPTION ;           -- �擾���R�[�h�Ȃ�
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �˗���f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    -- -----------------------------------------------------
    -- �˗���f�f�[�^�^�O�o��
    -- -----------------------------------------------------
    -- =====================================================
    -- �������擾����
    -- =====================================================
    prc_get_busho_data
      (
        iv_last_updated_user  =>   it_head_data(in_head_index).l_last_updated_user
       ,or_busho_data         =>   lr_busho_data
       ,ov_errbuf             =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- ���[�^�C�g��
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      lv_chohyo_title := gv_chohyo_title_irai;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'irai_sasizu_flg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_chohyo_kbn_irai;
--
    ELSE
      lv_chohyo_title := gv_chohyo_title_sasizu;
--
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'irai_sasizu_flg' ;
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := gv_chohyo_kbn_sasizu;
--
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_chohyo_title;
    -- ���[ID
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'chohyo_id';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := gc_report_id ;
    -- ���s��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'exec_time';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(id_now_date, gv_date_format2);
    -- �ϑ���
    IF (it_head_data(in_head_index).l_itaku_saki IS NOT NULL) THEN
      lv_itaku_saki := it_head_data(in_head_index).l_itaku_saki || gv_ontyu;
    ELSE
      lv_itaku_saki := NULL;
    END IF;
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'itaku_saki';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_itaku_saki;
    -- �Z��
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_address';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.address;
    -- ��zNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'tehai_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_tehai_no;
    -- TEL
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_tel';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.tel;
    -- FAX
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_fax';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.fax;
    -- �`�[�敪
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'den_kbn';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_den_kbn;
    -- �S������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'dep_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lr_busho_data.busho_nm;
    -- ���ъǗ�����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'knri_bsho';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_kanri_bsho;
    -- �i�ڃR�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_item_cd;
    -- �i�ږ���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'hinmk_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_item_nm;
    -- ���C��No
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_line_no;
    -- ���C������
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'line_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_line_nm;
    -- �[�i�ꏊ�R�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_set_cd;
    -- �[�i�ꏊ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'set_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_set_nm;
    -- ���Y�\���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'make_plan';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := TO_CHAR(it_head_data(in_head_index).l_make_plan, gv_date_format3);
    -- �������ɗ\���
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'stock_plan';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_stock_plan;
    -- ���b�gNo
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lot_no';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_lot_no;
    -- �ړ��ꏊ�R�[�h
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_cd';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_move_place_cd;
    -- �ړ��ꏊ����
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'move_nm';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_move_place_nm;
    -- �w�}����
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      ln_sasizu_total := it_head_data(in_head_index).l_irai_total;
    ELSE
-- 2009/02/02 v1.9 D.Nihei MOD START
--      ln_sasizu_total := it_head_data(in_head_index).l_plan_qty;
      ln_sasizu_total := it_head_data(in_head_index).l_inst_qty;
-- 2009/02/02 v1.9 D.Nihei MOD END
    END IF;
--
    IF (it_head_data(in_head_index).l_seizouhin_kbn = gv_seizouhin_kbn_drink) THEN
      ln_return_num := xxcmn_common_pkg.rcv_ship_conv_qty('2'
                                                          ,it_head_data(in_head_index).l_item_id
                                                          ,ln_sasizu_total);
    ELSE
      ln_return_num := ln_sasizu_total;
    END IF;
--
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'sashizu_total';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := ln_return_num;
    -- �^�C�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_type';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_type;
    -- �����N�P
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank1';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_rank1;
    -- �����N�Q
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_rank2';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_rank2;
    -- �E�v
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'item_tekiyo';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := it_head_data(in_head_index).l_description;
--
    -- -----------------------------------------------------
    -- ���ׂf�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_meisai_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id := -1;
-- 2008/10/28 v1.7 D.Nihei ADD END
    <<tonyu_data_loop>>
    FOR i IN 1..it_tonyu_data.COUNT LOOP
--
      -- ���׏��P���ڂ̏o�͂̏ꍇ
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- ���ׁi�����j�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD START
      IF ( ( lt_material_detail_id <> it_tonyu_data(i).l_material_detail_id ) OR ( it_tonyu_data(i).l_lot_no IS NOT NULL ) ) THEN
-- 2008/10/28 v1.7 D.Nihei ADD END
        -- -----------------------------------------------------
        -- �����f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �s�J�n�^�O
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- =====================================================
        -- ���ׁi�����j�^�C�g���擾����
        -- =====================================================
        -- �V�ʐ����C���̏ꍇ
        IF (it_tonyu_data(i).l_shinkansen_kbn = 'Y') THEN
          prc_get_mei_title_data
            (
              iv_material_detail_id  =>   it_tonyu_data(i).l_material_detail_id
             ,ov_mei_title           =>   lv_mei_title
             ,ov_errbuf              =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
             ,ov_retcode             =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
             ,ov_errmsg              =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
            );
--
          IF (lv_retcode = gv_status_error) THEN
            RAISE global_process_expt ;
          END IF ;
--
          IF (lv_mei_title IS NULL) THEN
            RAISE no_data_expt ;
          END IF;
--
          lv_mei_title := lv_mei_title || '����';
        ELSE
          lv_mei_title := gv_tonyu_title;
        END IF;
--
        IF (lv_break_mei_title <> lv_mei_title) THEN
          -- ���׃^�C�g��
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := '��' || lv_mei_title || '��';
--
          lv_break_mei_title := lv_mei_title;
--
        END IF;
--
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_item_cd ;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_hinmk_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_item_nm ;
        -- ���b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_lot_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_lot_no ;
        -- �ړ��ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_move_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_monve_no ;
        -- �q��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_souko';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_souko ;
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_make_day';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_make_date ;
        -- �݌ɓ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_stock';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_stock ;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_total';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2009/02/02 v1.9 D.Nihei MOD START
--        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_total * -1;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_total;
-- 2009/02/02 v1.9 D.Nihei MOD END
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'tonyu_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_tonyu_data(i).l_unit ;
        -- �s�I���^�O
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
      END IF;
      lt_material_detail_id := it_tonyu_data(i).l_material_detail_id;
-- 2008/10/28 v1.7 D.Nihei ADD END
      -- ���׏����o�͂����ꍇ
      IF (i = it_tonyu_data.COUNT) THEN
        -- -----------------------------------------------------
        -- ���ׁi�����j�f�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_tonyu';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP tonyu_data_loop ;
--
-- 2008/10/28 v1.7 D.Nihei ADD START
    lt_material_detail_id := -1;
-- 2008/10/28 v1.7 D.Nihei ADD END
    <<utikomi_data_loop>>
    FOR i IN 1..it_utikomi_data.COUNT LOOP
--
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- ���ׁi�ō��j�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
-- 2008/10/28 v1.7 D.Nihei ADD START
      IF ( ( lt_material_detail_id <> it_utikomi_data(i).l_material_detail_id ) OR ( it_utikomi_data(i).l_lot_no IS NOT NULL ) ) THEN
-- 2008/10/28 v1.7 D.Nihei ADD END
        -- -----------------------------------------------------
        -- �ō��f�f�[�^�^�O�o��
        -- -----------------------------------------------------
        -- �s�J�n�^�O
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
        -- ���׃^�C�g��
        IF (i = 1) THEN
          gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
          gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_title';
          gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
          gt_xml_data_table(gl_xml_idx).tag_value := gv_utikomi_title ;
        END IF;
        -- �i�ڃR�[�h
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_cd';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_item_cd;
        -- �i�ږ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_hinmk_nm';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_item_nm;
        -- ���b�gNo
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_lot_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_lot_no;
        -- �ړ��ԍ�
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_move_no';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_monve_no;
        -- �q��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_souko';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_souko;
        -- ������
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_make_day';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_make_date;
        -- �݌ɓ���
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_stock';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_stock;
        -- ����
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_total';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
-- 2009/02/02 v1.9 D.Nihei MOD START
--        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_total * -1;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_total;
-- 2009/02/02 v1.9 D.Nihei MOD END
        -- �P��
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'utikomi_unit';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := it_utikomi_data(i).l_unit;
        -- �s�I���^�O
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
-- 2008/10/28 v1.7 D.Nihei ADD START
      END IF;
      lt_material_detail_id := it_utikomi_data(i).l_material_detail_id;
-- 2008/10/28 v1.7 D.Nihei ADD END
      IF (i = it_utikomi_data.COUNT) THEN
        -- -----------------------------------------------------
        -- ���ׁi�����j�f�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_utikomi';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP utikomi_data_loop ;
--
    <<sizai_data_loop>>
    FOR i IN 1..it_sizai_data.COUNT LOOP
--
      IF (i = 1) THEN
        -- -----------------------------------------------------
        -- ���ׁi���ށj�f�J�n�^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_mei_sizai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
      -- -----------------------------------------------------
      -- ���ނf�f�[�^�^�O�o��
      -- -----------------------------------------------------
      -- �s�J�n�^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'g_mei_sizai';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      -- ���׃^�C�g��
      IF (i = 1) THEN
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_title';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
        gt_xml_data_table(gl_xml_idx).tag_value := gv_sizai_title;
      END IF;
      -- �i�ڃR�[�h
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_hinmk_cd';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_item_cd;
      -- �i�ږ���
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_hinmk_nm';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_item_nm;
      -- ����
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_total';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_total;
      -- �P��
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := 'sizai_unit';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
      gt_xml_data_table(gl_xml_idx).tag_value := it_sizai_data(i).l_unit;
      -- �s�I���^�O
      gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
      gt_xml_data_table(gl_xml_idx).tag_name  := '/g_mei_sizai';
      gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
      IF (i = it_sizai_data.COUNT) THEN
        -- -----------------------------------------------------
        -- ���ׁi�����j�f�I���^�O�o��
        -- -----------------------------------------------------
        gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
        gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_mei_sizai';
        gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
      END IF;
--
    END LOOP sizai_data_loop ;
--
    -- =====================================================
    -- �˗����o�͏I������
    -- =====================================================
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_meisai_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
    ------------------------------
    -- �˗���f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
    -- *** ���׃^�C�g���擾�f�[�^�O�� ***
    WHEN no_data_expt THEN
      ov_errmsg  := gv_err_mei_title_no_data ;
      ov_errbuf  := gv_err_mei_title_no_data ;
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
  END prc_create_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_create_zeroken_xml_data
   * Description      : �擾�����O�����w�l�k�f�[�^�쐬
   ***********************************************************************************/
  PROCEDURE prc_create_zeroken_xml_data
    (
      ir_param          IN  rec_param_data    -- ���R�[�h  �F�p�����[�^
     ,ov_errbuf         OUT VARCHAR2          -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode        OUT VARCHAR2          -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg         OUT VARCHAR2          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
    )
  IS
--
    -- =====================================================
    -- �Œ胍�[�J���萔
    -- =====================================================
    cv_prg_name    CONSTANT VARCHAR2(100) := 'prc_create_zeroken_xml_data' ; -- �v���O������
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
    -- ���[�^�C�g��
    lv_chohyo_title           VARCHAR2(10);
--
  BEGIN
--
    -- =====================================================
    -- ���ڃf�[�^���o�E�o�͏���
    -- =====================================================
    -- -----------------------------------------------------
    -- �˗���f�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    -- ���[�^�C�g��
    IF (ir_param.iv_chohyo_kbn = gv_chohyo_kbn_irai) THEN
      lv_chohyo_title := gv_chohyo_title_irai;
    ELSE
      lv_chohyo_title := gv_chohyo_title_sasizu;
    END IF;
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'head_title';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := lv_chohyo_title;
--
    -- -----------------------------------------------------
    -- ���ׂf�J�n�^�O�o��
    -- -----------------------------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'lg_meisai_info';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T';
--
    ------------------------------
    -- ���ׂk�f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/lg_meisai_info' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
    ------------------------------
    -- ���b�Z�[�W�o�̓^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := 'message';
    gt_xml_data_table(gl_xml_idx).tag_type  := 'D' ;
    gt_xml_data_table(gl_xml_idx).tag_value := xxcmn_common_pkg.get_msg( gc_application_cmn
                                                                        ,'APP-XXCMN-10122'  ) ;
--
    ------------------------------
    -- �˗���f�I���^�O
    ------------------------------
    gl_xml_idx := gt_xml_data_table.COUNT + 1 ;
    gt_xml_data_table(gl_xml_idx).tag_name  := '/g_irai' ;
    gt_xml_data_table(gl_xml_idx).tag_type  := 'T' ;
--
  EXCEPTION
--
    -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END prc_create_zeroken_xml_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_sizai_data
   * Description      : ���ޏ��擾
   ***********************************************************************************/
  PROCEDURE prc_get_sizai_data
    (
      iv_batch_id      IN  VARCHAR2                        -- �o�b�`ID
     ,ot_data_rec      OUT NOCOPY tab_sizai_data_type_dtl  -- �擾���R�[�h�Q
     ,ov_errbuf        OUT VARCHAR2                        -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode       OUT VARCHAR2                        -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg        OUT VARCHAR2                        -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_sizai_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_sizai_data
      (
        iv_batch_id            gme_batch_header.batch_id%TYPE
      )
    IS
      SELECT ximv.item_no             AS item_no            -- �i�ڃR�[�h
            ,ximv.item_short_name     AS item_desc1         -- �i�ږ���
-- 2008/10/28 v1.7 D.Nihei MOD START ������Q#499
--            ,gmd.attribute6           AS attribute6         -- �݌ɓ���
            ,ilm.attribute6           AS attribute6         -- �݌ɓ���
-- 2008/10/28 v1.7 D.Nihei MOD END
-- 2008/05/23 D.Nihei MOD START
--            ,xmd.instructions_qty     AS trans_qty          -- ����
            ,NVL(xmd.instructions_qty, gmd.attribute7) 
                                      AS trans_qty          -- ����
-- 2008/05/23 D.Nihei MOD END
            ,ximv.item_um             AS trans_um           -- �P��
      FROM gme_batch_header           gbh                   -- ���Y�o�b�`�w�b�_
          ,gme_material_details       gmd                   -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd                   -- ���Y�����ڍ׃A�h�I��
          ,ic_lots_mst                ilm                   -- OPM���b�g�}�X�^
          ,xxcmn_item_mst2_v          ximv                  -- OPM�i�ڃ}�X�^�r���[
          ,gmd_routings_vl            grv                   -- �H���}�X�^�r���[
          ,xxcmn_item_categories3_v   xicv                  -- �i�ڃJ�e�S���[�r���[
      WHERE gbh.batch_id              = gmd.batch_id
      AND   gmd.material_detail_id    = xmd.material_detail_id(+)
-- 2008/05/30 D.Nihei INS START
      AND   xmd.item_id               = ilm.item_id(+)
-- 2008/05/30 D.Nihei INS START
      AND   xmd.lot_id                = ilm.lot_id(+)
      AND   xmd.plan_type(+)          = gv_yotei_kbn_tonyu
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)    BETWEEN   TRUNC(ximv.start_date_active)
                                          AND       TRUNC(ximv.end_date_active)
      AND   gbh.routing_id            = grv.routing_id
      AND   gmd.item_id               = xicv.item_id
      --------------------------------------------------------------------------------------
      -- �i���ݏ���
      AND gmd.line_type               = gv_line_type_kbn_genryou
      AND gmd.attribute5              IS NULL
      AND xicv.item_class_code        = gv_hinmoku_kbn_sizai
      AND gbh.batch_id                = iv_batch_id
      ORDER BY TO_NUMBER(ximv.item_no)
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
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_sizai_data
      (
        iv_batch_id                    -- �o�b�`ID
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_sizai_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_sizai_data ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_sizai_data%ISOPEN THEN
        CLOSE cur_sizai_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_sizai_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_tonyu_utikomi_data
   * Description      : �������擾
   ***********************************************************************************/
  PROCEDURE prc_get_tonyu_utikomi_data
    (
      iv_utikomi_kbn         IN  VARCHAR2                             -- �ō��敪
     ,iv_batch_id            IN  VARCHAR2                             -- �o�b�`ID
     ,ot_data_rec            OUT NOCOPY tab_tonyu_utikomi_type_dtl    -- �擾���R�[�h
     ,ov_errbuf              OUT VARCHAR2                             -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT VARCHAR2                             -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT VARCHAR2                             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_tonyu_utikomi_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_tonyu_utikomi_data
      (
        iv_utikomi_kbn           VARCHAR
       ,iv_batch_id              gme_batch_header.batch_id%TYPE
      )
    IS
      SELECT ximv.item_no             AS item_no            -- �i�ڃR�[�h
            ,ximv.item_short_name     AS item_desc1         -- �i�ږ���
            ,DECODE(ilm.lot_id, 0, NULL,ilm.lot_no)
                                      AS lot_no             -- ���b�gno
-- 2008/05/30 D.Nihei MOD START
--            ,xmd.plan_number          AS plan_number        -- �ړ��ԍ�
            ,DECODE(xmd.plan_type, gv_yotei_kbn_mov, xmd.plan_number, NULL)
                                      AS plan_number        -- �ړ��ԍ�
-- 2008/05/30 D.Nihei MOD END
            ,xmd.location_code        AS location_code      -- �o�Ɍ��q��
-- 2008/10/28 v1.7 D.Nihei MOD START ������Q#499
--            ,gmd.attribute11          AS attribute11        -- ������
--            ,gmd.attribute6           AS attribute6         -- �݌ɓ���
            ,ilm.attribute1           AS attribute1         -- ������
            ,ilm.attribute6           AS attribute6         -- �݌ɓ���
-- 2008/10/28 v1.7 D.Nihei MOD END
-- 2009/02/02 v1.9 D.Nihei MOD START 
--            ,itp.trans_qty            AS trans_qty          -- ����
            ,NVL(xmd.instructions_qty, gmd.attribute7) 
                                      AS trans_qty          -- ����
-- 2009/02/02 v1.9 D.Nihei MOD END
            ,itp.trans_um             AS trans_um           -- �P��
            ,gmd.material_detail_id   AS material_detail_id -- ���Y�����ڍ�ID
            ,grv.attribute17          AS shinkansen_kbn     -- �V�ʐ��敪
      FROM gme_batch_header           gbh                   -- ���Y�o�b�`�w�b�_
          ,gme_material_details       gmd                   -- ���Y�����ڍ�
          ,xxwip_material_detail      xmd                   -- ���Y�����ڍ׃A�h�I��
          ,ic_tran_pnd                itp                   -- �ۗ��݌Ƀg�����U�N�V����
          ,ic_lots_mst                ilm                   -- OPM���b�g�}�X�^
          ,xxcmn_item_mst2_v          ximv                  -- OPM�i�ڃ}�X�^�r���[
          ,gmd_routings_vl            grv                   -- �H���}�X�^�r���[
          ,xxcmn_item_categories3_v   xicv                  -- �i�ڃJ�e�S���[�r���[
      WHERE gbh.batch_id              = gmd.batch_id
-- 2008/06/04 D.Nihei MOD START
--      AND   gmd.material_detail_id    = xmd.material_detail_id(+)
      AND   itp.line_id               = xmd.material_detail_id(+)
      AND   itp.item_id               = xmd.item_id(+)
      AND   itp.lot_id                = xmd.lot_id(+)
-- 2008/06/04 D.Nihei MOD END
-- 2008/05/30 D.Nihei MOD START
--      AND   xmd.plan_type(+)          = gv_yotei_kbn_tonyu
      AND   xmd.plan_type(+)         <> gv_yotei_kbn_tonyu
-- 2008/05/30 D.Nihei MOD END
      AND   gmd.material_detail_id    = itp.line_id
      AND   itp.lot_id                = ilm.lot_id
      AND   itp.item_id               = ilm.item_id
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)     BETWEEN   TRUNC(ximv.start_date_active)
                                           AND       TRUNC(ximv.end_date_active)
      AND   gbh.routing_id            = grv.routing_id
      AND   gmd.item_id               = xicv.item_id
      --------------------------------------------------------------------------------------
      -- �i���ݏ���
      AND gmd.line_type     = gv_line_type_kbn_genryou
      AND (
            (iv_utikomi_kbn IS NOT NULL AND gmd.attribute5    = iv_utikomi_kbn)
          OR
            (iv_utikomi_kbn IS NULL AND gmd.attribute5 IS NULL)
          )
      AND xicv.item_class_code IN (gv_hinmoku_kbn_genryou
                                  ,gv_hinmoku_kbn_hanseihin
                                  ,gv_hinmoku_kbn_seihin)
      AND itp.reverse_id          IS NULL
      AND ABS(itp.trans_qty)      > 0
      AND itp.delete_mark         = 0
      AND gbh.batch_id            = iv_batch_id
-- 2008/10/28 v1.7 D.Nihei ADD START ������Q#499
      AND itp.doc_type            = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
      ORDER BY  DECODE (iv_utikomi_kbn,
                        NULL, gmd.attribute8)
               ,xicv.item_class_code
               ,TO_NUMBER(ximv.item_no)
               ,TO_NUMBER(lot_no)
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
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_tonyu_utikomi_data
      (
        iv_utikomi_kbn                 -- �ō��敪
       ,iv_batch_id                    -- �o�b�`ID
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_tonyu_utikomi_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_tonyu_utikomi_data ;
--
  EXCEPTION
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_tonyu_utikomi_data%ISOPEN THEN
        CLOSE cur_tonyu_utikomi_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_tonyu_utikomi_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_get_head_data
   * Description      : �w�b�_�[���擾
   ***********************************************************************************/
  PROCEDURE prc_get_head_data
    (
      ir_param      IN  rec_param_data                     -- ���̓p�����[�^
     ,ot_data_rec   OUT NOCOPY tab_head_data_type_dtl      -- �擾���R�[�h
     ,ov_errbuf     OUT VARCHAR2                           -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode    OUT VARCHAR2                           -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg     OUT VARCHAR2                           -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_get_head_data'; -- �v���O������
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
--
    -- *** ���[�J���E�J�[�\�� ***
    CURSOR cur_head_data
      (
        iv_den_kbn              gmd_routings_vl.attribute13%TYPE
       ,iv_chohyo_kbn           VARCHAR
       ,iv_plant                gme_batch_header.plant_code%TYPE
       ,iv_line_no              gmd_routings_vl.routing_no%TYPE
       ,id_make_plan_from       gme_batch_header.plan_start_date%TYPE
       ,id_make_plan_to         gme_batch_header.plan_start_date%TYPE
       ,id_tehai_no_from        gme_batch_header.batch_no%TYPE
       ,id_tehai_no_to          gme_batch_header.batch_no%TYPE
       ,iv_hinmoku_cd           ic_item_mst_vl.item_no%TYPE
-- 2008/10/28 v1.7 D.Nihei MOD START
--       ,id_input_date_from      gmd_routings_vl.creation_date%TYPE
--       ,id_input_date_to        gmd_routings_vl.creation_date%TYPE
       ,id_input_date_from      gmd_routings_vl.last_update_date%TYPE
       ,id_input_date_to        gmd_routings_vl.last_update_date%TYPE
-- 2008/10/28 v1.7 D.Nihei MOD END
      )
    IS
      SELECT somv.orgn_name           AS l_itaku_saki             -- �ϑ���
            ,gbh.batch_no             AS l_tehai_no               -- ��zno
            ,xlvv1.meaning            AS l_den_kbn                -- �`�[�敪
            ,xlvv2.meaning            AS l_kanri_bsho             -- ���ъǗ�����
            ,ximv.item_no             AS l_item_cd                -- �i�ڃR�[�h
            ,ximv.item_short_name     AS l_item_nm                -- �i�ږ���
            ,grv.routing_no           AS l_line_no                -- ���C��no
            ,grv.routing_desc         AS l_line_nm                -- ���C������
            ,grv.attribute9           AS l_set_cd                 -- �[�i�ꏊ�R�[�h
            ,xilv1.description        AS l_set_nm                 -- �[�i�ꏊ����
            ,gbh.plan_start_date      AS l_make_plan              -- ���Y�\���
            ,gmd.attribute22          AS l_stock_plan             -- �������ɗ\���
            ,xlvv3.meaning            AS l_type                   -- �^�C�v
            ,gmd.attribute2           AS l_rank1                  -- �����N�P
            ,gmd.attribute3           AS l_rank2                  -- �����N�Q
            ,gmd.attribute4           AS l_description            -- �E�v
            ,ilm.lot_no               AS l_lot_no                 -- ���b�gno
            ,gmd.attribute12          AS l_move_place_cd          -- �ړ��ꏊ�R�[�h
            ,xilv2.description        AS l_move_place_nm          -- �ړ��ꏊ����
            ,gmd.attribute7           AS l_irai_total             -- �˗�����
            ,gmd.plan_qty             AS l_plan_qty               -- �v�搔
-- 2009/02/02 v1.9 D.Nihei ADD START
            ,gmd.attribute23          AS l_inst_qty               -- �w�}����
-- 2009/02/02 v1.9 D.Nihei ADD END
            ,grv.attribute16          AS l_seizouhin_kbn          -- �����i�敪
            ,gbh.batch_id             AS l_batch_id               -- �o�b�`ID
            ,gbh.last_updated_by      AS l_last_updated_user      -- �ŏI�X�V��
            ,ximv.item_id             AS l_hinmoku_id             -- �i��ID
      FROM gme_batch_header           gbh                         -- ���Y�o�b�`�w�b�_
          ,gme_material_details       gmd                         -- ���Y�����ڍ�
          ,ic_tran_pnd                itp                         -- �ۗ��݌Ƀg�����U�N�V����
          ,ic_lots_mst                ilm                         -- OPM���b�g�}�X�^
          ,xxcmn_item_mst2_v          ximv                        -- OPM�i�ڃ}�X�^�r���[
          ,sy_orgn_mst_vl             somv                        -- OPM�v�����g�}�X�^�r���[
          ,xxcmn_item_locations_v     xilv1                       -- OPM�ۊǏꏊ�}�X�^
          ,xxcmn_item_locations_v     xilv2                       -- OPM�ۊǏꏊ�}�X�^
          ,gmd_routings_vl            grv                         -- �H���}�X�^�r���[
          ,xxcmn_lookup_values_v      xlvv1                       -- �N�C�b�N�R�[�h�i�`�[�敪�j
          ,xxcmn_lookup_values_v      xlvv2                       -- �N�C�b�N�R�[�h�i���ъǗ������j
          ,xxcmn_lookup_values_v      xlvv3                       -- �N�C�b�N�R�[�h�i�^�C�v�j
      WHERE gbh.batch_id              = gmd.batch_id
      AND   gmd.material_detail_id    = itp.line_id(+)
      AND   itp.lot_id                = ilm.lot_id(+)
      AND   gmd.item_id               = ximv.item_id
      AND   TRUNC(gbh.plan_start_date)  BETWEEN   TRUNC(ximv.start_date_active)
                                        AND       TRUNC(ximv.end_date_active)
      AND    grv.attribute3           = somv.orgn_code(+)
      AND    grv.attribute9           = xilv1.segment1(+)
      AND    gmd.attribute12          = xilv2.segment1(+)
      AND    gbh.routing_id           = grv.routing_id
      AND    xlvv1.lookup_type(+)     = 'XXCMN_L03'
      AND    xlvv1.lookup_code(+)     = grv.attribute13
      AND    xlvv2.lookup_type(+)     = 'XXCMN_L10'
      AND    xlvv2.lookup_code(+)     = grv.attribute14
      AND    xlvv3.lookup_type(+)     = 'XXCMN_L08'
      AND    xlvv3.lookup_code(+)     = gmd.attribute1
      --------------------------------------------------------------------------------------
      -- �i���ݏ���
      AND grv.attribute13             = NVL(iv_den_kbn, grv.attribute13)
      AND gbh.plant_code              = iv_plant
      AND grv.routing_no              = NVL(iv_line_no, grv.routing_no)
-- 2008/10/28 v1.7 D.Nihei MOD START
--      AND TRUNC(gbh.creation_date, 'MI') BETWEEN TRUNC(id_input_date_from, 'MI')
      AND TRUNC(gbh.last_update_date, 'MI') BETWEEN TRUNC(id_input_date_from, 'MI')
-- 2008/10/28 v1.7 D.Nihei MOD END
                                            AND     TRUNC(id_input_date_to, 'MI')
      AND gbh.batch_no                >= NVL(id_tehai_no_from, gbh.batch_no)
      AND gbh.batch_no                <= NVL(id_tehai_no_to, gbh.batch_no)
      AND TRUNC(gbh.plan_start_date)  >= NVL(id_make_plan_from, TRUNC(gbh.plan_start_date))
      AND TRUNC(gbh.plan_start_date)  <= NVL(id_make_plan_to, TRUNC(gbh.plan_start_date))
      AND ximv.item_no                = NVL(iv_hinmoku_cd, ximv.item_no)
      AND (
            (    iv_chohyo_kbn        = gv_chohyo_kbn_irai
             AND gbh.attribute4         IN( gv_status_irai_zumi     -- �˗���
-- 2008/07/18 H.Itou ADD START  ���[�敪���˗����̏ꍇ�A�ۗ����E��z�ς��ΏۂƂ���B
                                           ,gv_status_horyu         -- �ۗ���
                                           ,gv_status_tehai_zumi    -- ��z��
-- 2008/07/18 H.Itou ADD END
                                           ,gv_status_kakunin_zumi  -- �m�F��
                                           ,gv_status_uketuke_zumi )-- ��t��
            )
           OR
            (    iv_chohyo_kbn        = gv_chohyo_kbn_sasizu
             AND gbh.attribute4         IN( gv_status_sasizu_zumi
-- 2008/10/28 v1.7 D.Nihei ADD START
                                           ,gv_status_tehai_zumi    -- ��z��
-- 2008/10/28 v1.7 D.Nihei ADD END
-- 2009/01/16 v1.8 D.Nihei ADD START
                                           ,gv_status_kakunin_zumi  -- �m�F��
-- 2009/01/16 v1.8 D.Nihei ADD END
                                           ,gv_status_uketuke_zumi )
            )
          )
      AND gmd.line_type               = gv_line_type_kbn_seizouhin
      AND itp.reverse_id(+)           IS NULL
      AND itp.lot_id(+)               > 0
      AND itp.delete_mark(+)          = 0
-- 2008/10/28 v1.7 D.Nihei ADD START
      AND itp.doc_type(+)             = gv_doc_type_prod
-- 2008/10/28 v1.7 D.Nihei ADD END
      ORDER BY gbh.batch_no
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
    -- �f�[�^���o
    -- ====================================================
    -- �J�[�\���I�[�v��
    OPEN cur_head_data
      (
        ir_param.iv_den_kbn            -- �`�[�敪
       ,ir_param.iv_chohyo_kbn         -- ���[�敪
       ,ir_param.iv_plant              -- �v�����g
       ,ir_param.iv_line_no            -- ���C��No
       ,ir_param.id_make_plan_from     -- ���Y�\���(FROM)
       ,ir_param.id_make_plan_to       -- ���Y�\���(TO)
       ,ir_param.id_tehai_no_from      -- ��zNo(FROM)
       ,ir_param.id_tehai_no_to        -- ��zNo(TO)
       ,ir_param.iv_hinmoku_cd         -- �i�ڃR�[�h
       ,ir_param.id_input_date_from    -- ���͓���(FROM)
       ,ir_param.id_input_date_to      -- ���͓���(TO)
      ) ;
    -- �o���N�t�F�b�`
    FETCH cur_head_data BULK COLLECT INTO ot_data_rec ;
    -- �J�[�\���N���[�Y
    CLOSE cur_head_data ;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
      ov_retcode := gv_status_error ;
--
--#################################  �Œ��O������ START   ####################################
--
    -- *** ���ʊ֐���O�n���h�� ***
    WHEN global_api_expt THEN
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000);
      ov_retcode := gv_status_error;
    -- *** ���ʊ֐�OTHERS��O�n���h�� ***
    WHEN global_api_others_expt THEN
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
    -- *** OTHERS��O�n���h�� ***
    WHEN OTHERS THEN
      IF cur_head_data%ISOPEN THEN
        CLOSE cur_head_data ;
      END IF ;
      ov_errbuf  := gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||SQLERRM;
      ov_retcode := gv_status_error;
--
--#####################################  �Œ蕔 END   ##########################################
--
  END prc_get_head_data ;
--
  /**********************************************************************************
   * Procedure Name   : prc_check_param_data
   * Description      : �p�����[�^�`�F�b�N����
   ***********************************************************************************/
  PROCEDURE prc_check_param_data
    (
      iv_make_plan_from      IN  VARCHAR2                     -- ���Y�\���(FROM)
     ,iv_make_plan_to        IN  VARCHAR2                     -- ���Y�\���(TO)
     ,iv_input_date_from     IN  VARCHAR2                     -- ���͓���(FROM)
     ,iv_input_date_to       IN  VARCHAR2                     -- ���͓���(TO)
     ,id_now_date            IN  DATE                         -- ���ݓ��t
     ,od_make_plan_from      OUT DATE                         -- ���Y�\���(FROM)
     ,od_make_plan_to        OUT DATE                         -- ���Y�\���(TO)
     ,od_input_date_from     OUT DATE                         -- ���͓���(FROM)
     ,od_input_date_to       OUT DATE                         -- ���͓���(TO)
     ,ov_errbuf              OUT VARCHAR2                     -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode             OUT VARCHAR2                     -- ���^�[���E�R�[�h             --# �Œ� #
     ,ov_errmsg              OUT VARCHAR2                     -- ���[�U�[�E�G���[�E���b�Z�[�W   --# �Œ� #
    )
  IS
    -- ===============================
    -- �Œ胍�[�J���萔
    -- ===============================
    cv_prg_name   CONSTANT VARCHAR2(100) := 'prc_check_param_data'; -- �v���O������
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
    -- ���ʊ֐��߂�l�F���l�^
    ln_ret_num              NUMBER ;
--
    -- *** ���[�J���E��O���� ***
    parameter_check_expt      EXCEPTION ;     -- �p�����[�^�`�F�b�N��O
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
    -- ���t�`�F�b�N
    -- ====================================================
    IF (iv_make_plan_from IS NOT NULL) THEN
      ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_make_plan_from) ;
      IF ( ln_ret_num = 1 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                              ,'APP-XXCMN-10012'
                                              ,gv_tkn_item
                                              ,gv_err_make_plan_from
                                              ,gv_tkn_value
                                              ,iv_make_plan_from) ;
        RAISE parameter_check_expt ;
      ELSE
-- �ύX START 2008/05/20 YTabata
/**
        od_make_plan_from := FND_DATE.STRING_TO_DATE(iv_make_plan_from
                                                    ,gv_date_format1);
**/
-- �ύX END 2008/05/20 YTabata
        od_make_plan_from := FND_DATE.CANONICAL_TO_DATE(iv_make_plan_from) ;
      END IF ;
    END IF;
--
    IF (iv_make_plan_to IS NOT NULL) THEN
      ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_make_plan_to) ;
      IF ( ln_ret_num = 1 ) THEN
        lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_make_plan_to
                                            ,gv_tkn_value
                                            ,iv_make_plan_to) ;
        RAISE parameter_check_expt ;
      ELSE
-- �ύX START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_make_plan_to
                                                  ,gv_date_format1);
**/
-- �ύX END 2008/05/20 YTabata
        od_make_plan_to := FND_DATE.CANONICAL_TO_DATE(iv_make_plan_to) ;
      END IF ;
    END IF;
--
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_input_date_from) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,iv_input_date_from) ;
      RAISE parameter_check_expt ;
    ELSE
-- �ύX START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_input_date_from
                                                  ,gv_date_format1);
**/
-- �ύX END 2008/05/20 YTabata
      od_input_date_from := FND_DATE.CANONICAL_TO_DATE(iv_input_date_from);
    END IF ;
--
    ln_ret_num := xxcmn_common_pkg.check_param_date_yyyymmdd(iv_input_date_to) ;
    IF ( ln_ret_num = 1 ) THEN
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_cmn
                                            ,'APP-XXCMN-10012'
                                            ,gv_tkn_item
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,iv_input_date_to) ;
      RAISE parameter_check_expt ;
    ELSE
-- �ύX START 2008/05/20 YTabata
/**
        od_make_plan_to := FND_DATE.STRING_TO_DATE(iv_input_date_to
                                                  ,gv_date_format1);
**/
-- �ύX END 2008/05/20 YTabata
      od_input_date_to := FND_DATE.CANONICAL_TO_DATE(iv_input_date_to);
    END IF ;
--
    -- ====================================================
    -- �������`�F�b�N
    -- ====================================================
    IF (TRUNC(od_input_date_from, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_from
                                            ,gv_tkn_value
                                            ,TO_CHAR(od_input_date_from, gv_date_format2)) ;
      RAISE parameter_check_expt ;
    END IF;
--    
    IF (TRUNC(od_input_date_to, 'DD') > TRUNC(id_now_date, 'DD')) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10001'
                                            ,gv_tkn_date
                                            ,gv_err_input_date_to
                                            ,gv_tkn_value
                                            ,TO_CHAR(od_input_date_to, gv_date_format2)) ;
      RAISE parameter_check_expt ;
    END IF;
--
    -- ====================================================
    -- �Ó����`�F�b�N
    -- ====================================================
    IF (od_input_date_from > od_input_date_to) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_input_date_from
                                            ,gv_tkn_param2
                                            ,gv_err_input_date_to) ;
      RAISE parameter_check_expt ;
    END IF;
--
    IF (od_make_plan_from > od_make_plan_to) THEN
      -- ���b�Z�[�W�Z�b�g
      lv_errmsg := xxcmn_common_pkg.get_msg( gc_application_wip
                                            ,'APP-XXWIP-10016'
                                            ,gv_tkn_param1
                                            ,gv_err_make_plan_from
                                            ,gv_tkn_param2
                                            ,gv_err_make_plan_to) ;
      RAISE parameter_check_expt ;
    END IF;
--
  EXCEPTION
    --*** �p�����[�^�`�F�b�N��O ***
    WHEN parameter_check_expt THEN
--
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
  END prc_check_param_data ;
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : ���C�������v���V�[�W��
   **********************************************************************************/
  PROCEDURE submain
    (
      iv_den_kbn            IN     VARCHAR2         -- 01 : �`�[�敪
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : ���[�敪
     ,iv_plant              IN     VARCHAR2         -- 03 : �v�����g
     ,iv_line_no            IN     VARCHAR2         -- 04 : ���C��No
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : ���Y�\���(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : ���Y�\���(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : ��zNo(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : ��zNo(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : �i�ڃR�[�h
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : ���͓���(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : ���͓���(TO)
     ,ov_errbuf            OUT     VARCHAR2         -- �G���[�E���b�Z�[�W           --# �Œ� #
     ,ov_retcode           OUT     VARCHAR2         -- ���^�[���E�R�[�h            --# �Œ� #
     ,ov_errmsg            OUT     VARCHAR2         -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
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
    lr_param_rec            rec_param_data ;               -- �p�����[�^��n���p
    lt_head_data            tab_head_data_type_dtl ;       -- �擾���R�[�h�\�i�w�b�_�[���j
    lt_tonyu_data           tab_tonyu_utikomi_type_dtl ;   -- �擾���R�[�h�\�i�������j
    lt_utikomi_data         tab_tonyu_utikomi_type_dtl ;   -- �擾���R�[�h�\�i�ō����j
    lt_sizai_data           tab_sizai_data_type_dtl ;      -- �擾���R�[�h�\�i���ޏ��j
    lr_busho_data           rec_busho_data;                -- �擾���R�[�h�\�i�������j
    ld_make_plan_from       DATE DEFAULT NULL;
    ld_make_plan_to         DATE DEFAULT NULL;
    ld_input_date_from      DATE DEFAULT NULL;
    ld_input_date_to        DATE DEFAULT NULL;
--
    -- �V�X�e�����t
    ld_now_date             DATE DEFAULT SYSDATE;
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
    -- �p�����[�^�`�F�b�N
    -- =====================================================
    prc_check_param_data
      (
        iv_make_plan_from       =>   iv_make_plan_from     -- ���Y�\���(FROM)
       ,iv_make_plan_to         =>   iv_make_plan_to       -- ���Y�\���(TO)
       ,iv_input_date_from      =>   iv_input_date_from    -- ���͓���(TROM)
       ,iv_input_date_to        =>   iv_input_date_to      -- ���͓���(TO)
       ,id_now_date             =>   ld_now_date           -- ���ݓ��t
       ,od_make_plan_from       =>   ld_make_plan_from     -- ���Y�\���(FROM)
       ,od_make_plan_to         =>   ld_make_plan_to       -- ���Y�\���(TO)
       ,od_input_date_from      =>   ld_input_date_from    -- ���͓���(TROM)
       ,od_input_date_to        =>   ld_input_date_to      -- ���͓���(TO)
       ,ov_errbuf               =>   lv_errbuf             -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode              =>   lv_retcode            -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg               =>   lv_errmsg             -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      ) ;
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    -- =====================================================
    -- �p�����[�^�i�[����
    -- =====================================================
    lr_param_rec.iv_den_kbn          := iv_den_kbn;                                  -- 01 : �`�[�敪
    lr_param_rec.iv_chohyo_kbn       := iv_chohyo_kbn;                               -- 02 : ���[�敪
    lr_param_rec.iv_plant            := iv_plant;                                    -- 03 : �v�����g
    lr_param_rec.iv_line_no          := iv_line_no;                                  -- 04 : ���C��No
    lr_param_rec.id_make_plan_from   := ld_make_plan_from;                           -- 05 : ���Y�\���(FROM)
    lr_param_rec.id_make_plan_to     := ld_make_plan_to;                             -- 06 : ���Y�\���(TO)
    lr_param_rec.id_tehai_no_from    := iv_tehai_no_from;                            -- 07 : ��zNo(FROM)
    lr_param_rec.id_tehai_no_to      := iv_tehai_no_to;                              -- 08 : ��zNo(TO)
    lr_param_rec.iv_hinmoku_cd       := iv_hinmoku_cd;                               -- 09 : �i�ڃR�[�h
    lr_param_rec.id_input_date_from  := ld_input_date_from;                          -- 10 : ���͓���(FROM)
    lr_param_rec.id_input_date_to    := ld_input_date_to;                            -- 11 : ���͓���(TO)
--
    -- =====================================================
    -- �w�b�_�[���擾����
    -- =====================================================
    prc_get_head_data
      (
        ir_param          =>   lr_param_rec       -- ���̓p�����[�^���R�[�h
       ,ot_data_rec       =>   lt_head_data       -- �擾���R�[�h�Q
       ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
      );
--
    IF ( lv_retcode = gv_status_error ) THEN
      RAISE global_process_expt ;
    END IF ;
--
    <<head_data_loop>>
    FOR i IN 1..lt_head_data.COUNT LOOP
      -- =====================================================
      -- ���ׁi�����j���擾����
      -- =====================================================
      prc_get_tonyu_utikomi_data
        (
          iv_utikomi_kbn         =>   NULL                         -- �ō��敪
         ,iv_batch_id            =>   lt_head_data(i).l_batch_id   -- �o�b�`ID
         ,ot_data_rec            =>   lt_tonyu_data                -- �擾���R�[�h�Q
         ,ov_errbuf              =>   lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode             =>   lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg              =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ���ׁi�ō��j���擾����
      -- =====================================================
      prc_get_tonyu_utikomi_data
        (
          iv_utikomi_kbn         =>   gv_utikomi_kbn_utikomi       -- �ō��敪
         ,iv_batch_id            =>   lt_head_data(i).l_batch_id   -- �o�b�`ID
         ,ot_data_rec            =>   lt_utikomi_data              -- 02.�擾���R�[�h�Q
         ,ov_errbuf              =>   lv_errbuf                    -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode             =>   lv_retcode                   -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg              =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ���ׁi�������ށj���擾����
      -- =====================================================
      prc_get_sizai_data
        (
          iv_batch_id       =>   lt_head_data(i).l_batch_id   -- �o�b�`ID
         ,ot_data_rec       =>   lt_sizai_data                -- �擾���R�[�h�Q
         ,ov_errbuf         =>   lv_errbuf                    -- �G���[�E���b�Z�[�W          --# �Œ� #
         ,ov_retcode        =>   lv_retcode                   -- ���^�[���E�R�[�h            --# �Œ� #
         ,ov_errmsg         =>   lv_errmsg                    -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
        );
--
      IF ( lv_retcode = gv_status_error ) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- XML�f�[�^�쐬����
      -- =====================================================
      prc_create_xml_data
        (
          ir_param          =>   lr_param_rec       -- ���̓p�����[�^���R�[�h
         ,in_head_index     =>   i                  -- �w�b�_�[���index
         ,it_head_data      =>   lt_head_data       -- �w�b�_�[���
         ,it_tonyu_data     =>   lt_tonyu_data      -- �������
         ,it_utikomi_data   =>   lt_utikomi_data    -- �ō����
         ,it_sizai_data     =>   lt_sizai_data      -- ���ޏ��
         ,id_now_date       =>   ld_now_date        -- ���ݓ��t
         ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
      -- =====================================================
      -- ����������
      -- =====================================================
      lt_tonyu_data.delete;
      lt_utikomi_data.delete;
      lt_sizai_data.delete;
--
    END LOOP head_data_loop ;
--
    IF (lt_head_data.COUNT = 0) THEN
--
      -- =====================================================
      -- �擾�f�[�^�O����XML�f�[�^�쐬����
      -- =====================================================
      prc_create_zeroken_xml_data
        (
          ir_param          =>   lr_param_rec       -- ���̓p�����[�^���R�[�h
         ,ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
         ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
         ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
        );
--
      IF (lv_retcode = gv_status_error) THEN
        RAISE global_process_expt ;
      END IF ;
--
    END IF;
--
    -- =====================================================
    -- XML�f�[�^�o�͏���
    -- =====================================================
    prc_out_xml_data
      (
        ov_errbuf         =>   lv_errbuf          -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode        =>   lv_retcode         -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg         =>   lv_errmsg          -- ���[�U�[�E�G���[�E���b�Z�[�W  --# �Œ� #
      );
--
    IF (lv_retcode = gv_status_error) THEN
      RAISE global_process_expt ;
    END IF ;
--
    IF (lv_retcode = gv_status_normal AND lt_head_data.COUNT = 0) THEN
      lv_retcode := gv_status_warn;
    END IF;
--
    -- ==================================================
    -- �I���X�e�[�^�X�ݒ�
    -- ==================================================
    ov_retcode := lv_retcode ;
    ov_errmsg  := lv_errmsg ;
    ov_errbuf  := lv_errbuf ;
--
  EXCEPTION
      -- *** ���������ʗ�O�n���h�� ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg ;
      ov_errbuf  := SUBSTRB(gv_pkg_name||gv_msg_cont||cv_prg_name||gv_msg_part||lv_errbuf,1,5000) ;
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
  END submain ;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : �R���J�����g���s�t�@�C���o�^�v���V�[�W��
   **********************************************************************************/
  PROCEDURE main
    (
      errbuf                OUT    VARCHAR2         -- �G���[���b�Z�[�W
     ,retcode               OUT    VARCHAR2         -- �G���[�R�[�h
     ,iv_den_kbn            IN     VARCHAR2         -- 01 : �`�[�敪
     ,iv_chohyo_kbn         IN     VARCHAR2         -- 02 : ���[�敪
     ,iv_plant              IN     VARCHAR2         -- 03 : �v�����g
     ,iv_line_no            IN     VARCHAR2         -- 04 : ���C��No
     ,iv_make_plan_from     IN     VARCHAR2         -- 05 : ���Y�\���(FROM)
     ,iv_make_plan_to       IN     VARCHAR2         -- 06 : ���Y�\���(TO)
     ,iv_tehai_no_from      IN     VARCHAR2         -- 07 : ��zNo(FROM)
     ,iv_tehai_no_to        IN     VARCHAR2         -- 08 : ��zNo(TO)
     ,iv_hinmoku_cd         IN     VARCHAR2         -- 09 : �i�ڃR�[�h
     ,iv_input_date_from    IN     VARCHAR2         -- 10 : ���͓���(FROM)
     ,iv_input_date_to      IN     VARCHAR2         -- 11 : ���͓���(TO)
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
    submain
      (
        iv_den_kbn            => iv_den_kbn           -- 01 : �`�[�敪
       ,iv_chohyo_kbn         => iv_chohyo_kbn        -- 02 : ���[�敪
       ,iv_plant              => iv_plant             -- 03 : �v�����g
       ,iv_line_no            => iv_line_no           -- 04 : ���C��No
       ,iv_make_plan_from     => iv_make_plan_from    -- 05 : ���Y�\���(FROM)
       ,iv_make_plan_to       => iv_make_plan_to      -- 06 : ���Y�\���(TO)
       ,iv_tehai_no_from      => iv_tehai_no_from     -- 07 : ��zNo(FROM)
       ,iv_tehai_no_to        => iv_tehai_no_to       -- 08 : ��zNo(TO)
       ,iv_hinmoku_cd         => iv_hinmoku_cd        -- 09 : �i�ڃR�[�h
       ,iv_input_date_from    => iv_input_date_from   -- 10 : ���͓���(FROM)
       ,iv_input_date_to      => iv_input_date_to     -- 11 : ���͓���(TO)
       ,ov_errbuf             => lv_errbuf            -- �G���[�E���b�Z�[�W           --# �Œ� #
       ,ov_retcode            => lv_retcode           -- ���^�[���E�R�[�h             --# �Œ� #
       ,ov_errmsg             => lv_errmsg            -- ���[�U�[�E�G���[�E���b�Z�[�W --# �Œ� #
     ) ;
--
--###########################  �Œ蕔 START   #####################################################
--
    -- ======================================================
    -- �G���[�E���b�Z�[�W�o��
    -- ======================================================
    IF ( lv_retcode = gv_status_error ) THEN
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
END xxwip230001c ;
/
