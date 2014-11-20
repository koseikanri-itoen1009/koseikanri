CREATE OR REPLACE PACKAGE APPS.XXCOS002A02R
AS
/*****************************************************************************************
 * Copyright(c)Sumisho Computer Systems Corporation, 2008. All rights reserved.
 *
 * Package Name     : XXCOS002A02R(spec)
 * Description      : �c�ƕ񍐓���
 * MD.050           : �c�ƕ񍐓��� MD050_COS_002_A02
 * Version          : 1.9
 *
 * Program List
 * -------------------- ------------------------------------------------------------
 *  Name                 Description
 * -------------------- ------------------------------------------------------------
 *  main                 �R���J�����g���s�t�@�C���o�^�v���V�[�W��
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2008/12/11    1.0   T.Nakabayashi    main�V�K�쐬
 *  2009/02/20    1.1   T.Nakabayashi    get_msg�̃p�b�P�[�W���C��
 *  2009/02/26    1.2   T.Nakabayashi    MD050�ۑ�No153�Ή� �]�ƈ��A�A�T�C�������g�K�p�����f�ǉ�
 *  2009/02/27    1.3   T.Nakabayashi    ���[���[�N�e�[�u���폜���� �R�����g�A�E�g����
 *  2009/05/01    1.4   K.Kiriu          [T1_0481]�K��f�[�^���o��������Ή�
 *  2009/06/03    1.5   T.Kitajima       [T1_1172]�W��L�[�Ɍڋq�R�[�h�ǉ�
 *  2009/06/03    1.5   T.Kitajima       [T1_1301]�[�i�`�[�ԍ����ނŏW�񂷂�悤�ɕύX
 *  2009/06/19    1.6   K.Kiriu          [T1_1437]�f�[�^�p�[�W�s��Ή�
 *  2009/07/08    1.7   T.Tominaga       [0000477]�`�[���v���z�Z�o�����폜
 *                                                A-3.�[�i���уf�[�^�}��������key brake�ǉ�
 *                                                A-2,A-3��A�ō����������v���z�ōX�V���鏈����ǉ�
 *                                                �[�i���я��J�[�\���̓����z�擾�ύX
 *                                                �[�i���я��J�[�\���̃\�[�g�ɔ̔����уw�b�_.HHT�[�i���͓�����ǉ�
 *  2009/07/15    1.7   T.Tominaga       [0000659]�[�i���я��J�[�\���̖{�̋��z�𔄏���z�ɕύX�iaftertax_sale, sale_discount�j
 *                                       [0000665]�[�i���я��J�[�\���̏��i����OPM�i�ڃA�h�I���̗��̂ɕύX
 *  2009/07/22    1.7   T.Tominaga       �����z�̎擾��[�i���я��J�[�\������A-3.�[�i���уf�[�^�}���������ŕʓr�擾�ɕύX
 *  2009/09/02    1.8   K.Kiriu          [0000900]PT�Ή�
 *                                       [0001273]�W���݂̂̒��o�����s���Ή�
 *  2009/10/30    1.9   M.Sano           [0001373]�Q�ƃr���[�ύX�FXXCOS_RS_INFO_V��XXCOS_RS_INFO2_V
 *
 *****************************************************************************************/
--
  --�R���J�����g���s�t�@�C���o�^�v���V�[�W��
  PROCEDURE main(
    errbuf                OUT     VARCHAR2,         --  �G���[���b�Z�[�W #�Œ�#
    retcode               OUT     VARCHAR2,         --  �G���[�R�[�h     #�Œ�#
    iv_delivery_date      IN      VARCHAR2,         --  1.�[�i��
    iv_delivery_base_code IN      VARCHAR2,         --  2.�[�i���_
    iv_dlv_by_code        IN      VARCHAR2          --  3.�c�ƈ��i�[�i�ҁj
  );
END XXCOS002A02R;
/
