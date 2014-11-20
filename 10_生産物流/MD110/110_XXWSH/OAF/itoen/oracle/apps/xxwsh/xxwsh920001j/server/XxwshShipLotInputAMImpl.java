/*============================================================================
* �t�@�C���� : XxwshShipLotInputAMImpl
* �T�v����   : ���o�׎��у��b�g���͉�ʃA�v���P�[�V�������W���[��
* �o�[�W���� : 1.4
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-27 1.0  �ɓ��ЂƂ�   �V�K�쐬
* 2008-06-13 1.1  �ɓ��ЂƂ�   �o�׎��ьv��ςł��o�׎��ѐ��ʂɓo�^���Ȃ��ꍇ�͎󒍕��ʏ������s��Ȃ��B
* 2008-06-13 1.2  �ɓ��ЂƂ�   �o�׎��ьv��ςł��w�b�_�ɕR�t���o�׎��ѐ��ʂ�
*                              ���ׂēo�^�Ϗo�׎��ѐ��ʂɓo�^���Ȃ��ꍇ��
*                              �󒍕��ʏ������s��Ȃ��B
* 2008-06-27 1.3  �ɓ��ЂƂ�   �����s�TE080_400#157
* 2008-07-23 1.4  �ɓ��ЂƂ�   �����ۑ�#32  ���Z����ꍇ�ŁA�P�[�X������0�ȉ��̓G���[
*                              �����ύX#174 ���ьv��ϋ敪��Y�̏ꍇ�̂ݎ󒍃R�s�[�������s��
*============================================================================
*/
package itoen.oracle.apps.xxwsh.xxwsh920001j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxwsh.util.XxwshConstants;
import itoen.oracle.apps.xxwsh.util.XxwshUtility;

import java.sql.SQLException;

import oracle.apps.fnd.common.MessageToken;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * ���o�׎��у��b�g���͉�ʃA�v���P�[�V�������W���[���ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.3
 ***************************************************************************
 */
public class XxwshShipLotInputAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxwshShipLotInputAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxwsh.xxwsh920001j.server", "XxwshShipLotInputAMLocal");
  }
  
  /***************************************************************************
   * �������������s�����\�b�h�ł��B
   * @param params - �p�����[�^
   ***************************************************************************
   */
  public void initialize(HashMap params)
  {
    // *********************** //
    // *    PVO ������       * //
    // *********************** //
    OAViewObject pvo = getXxwshShipLotInputPVO1();   
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!pvo.isPreparedForExecution())
    {    
      // 1�s���Ȃ��ꍇ�A��s�쐬
      pvo.setMaxFetchSize(0);
      pvo.executeQuery();
      pvo.insertRow(pvo.createRow());
      // 1�s�ڂ��擾
      OARow pvoRow = (OARow)pvo.first();
      // �L�[�ɒl���Z�b�g
      pvoRow.setAttribute("RowKey", new Number(1));
    }    
   
    // *********************** //
    // *  �p�����[�^�`�F�b�N * //
    // *********************** //
    checkParams(params);

    // *********************** //
    // *   �\���f�[�^�擾    * //
    // *********************** //
    doSearch(params);

  }

  /***************************************************************************
   * �����������s�����\�b�h�ł��B
   * @param params       - �p�����[�^
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearch(HashMap params) throws OAException
  {
    // �p�����[�^�擾
    String orderLineId      = (String)params.get("orderLineId");      // �󒍖��׃A�h�I��ID
    String callPictureKbn   = (String)params.get("callPictureKbn");   // �ďo��ʋ敪
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // ���׍X�V����
    String exeKbn           = (String)params.get("exeKbn");           // �N���敪   
    String recordTypeCode   = (String)params.get("recordTypeCode");   // ���R�[�h�^�C�v 20:�o�Ɏ��� 30:���Ɏ���
    String documentTypeCode = null; // �����^�C�v

    // �����^�C�v����
    // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      documentTypeCode = XxwshConstants.DOC_TYPE_SHIP; // 10:�o�׈˗�

    // ����ȊO�̏ꍇ
    } else
    {
      documentTypeCode = XxwshConstants.DOC_TYPE_SUPPLY; // 30:�x���w��
    }

// 2008-07-23 H.Itou ADD START
    // ************************* //    
    // *   �P�[�X�����`�F�b�N  * //
    // ************************* //
    // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ̏ꍇ�̂݃`�F�b�N
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      // ����ID����i�ڃR�[�h���擾
      String itemCode = XxwshUtility.getItemCode(getOADBTransaction(), orderLineId);

       // ���Z����ꍇ�ɁA�i�ڂ̃P�[�X����0�ȉ��̒l�̏ꍇ�A�G���[
      if (!XxwshUtility.checkNumOfCases(getOADBTransaction(), itemCode))
      {
        // ���ڐ���(�߂�{�^���ȊO��\��
        itemControl(XxcmnConstants.STRING_Y);
      
        // �g�[�N������
        MessageToken[] tokens = { new MessageToken(XxcmnConstants.TOKEN_ITEM_NO, itemCode) };

        // �G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN,
          XxcmnConstants.XXCMN10605,
          tokens);

      }
    }   
// 2008-07-23 H.Itou ADD END

    // ********************** //    
    // *   ���׌���         * //
    // ********************** //
    XxwshLineVOImpl lineVo = getXxwshLineVO1();
    lineVo.initQuery(
      orderLineId,
      callPictureKbn);
      
    // ���ׂ��擾�ł��Ȃ������ꍇ
    if (lineVo.getRowCount() == 0)
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    } 
    // 1�s�ڂ��擾
    OARow lineRow = (OARow)lineVo.first();
    // �p�����[�^���Z�b�g

    lineRow.setAttribute("OrderLineId",       orderLineId);      // �󒍖��׃A�h�I��ID
    lineRow.setAttribute("CallPictureKbn",    callPictureKbn);   // �ďo��ʋ敪
    lineRow.setAttribute("HeaderUpdateDate",  headerUpdateDate); // �w�b�_�X�V����
    lineRow.setAttribute("LineUpdateDate",    lineUpdateDate);   // ���׍X�V����
    lineRow.setAttribute("ExeKbn",            exeKbn);           // �N���敪 
    lineRow.setAttribute("DocumentTypeCode",  documentTypeCode); // �����^�C�v
    lineRow.setAttribute("RecordTypeCode",    recordTypeCode);   // ���R�[�h�^�C�v
    
    // �l�擾
    String itemClassCode = (String)lineRow.getAttribute("ItemClassCode"); // �i�ڋ敪
    Number numOfCases    = (Number)lineRow.getAttribute("NumOfCases");    // �P�[�X����

    // *********************** //
    // *      ���ڐ���       * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N);
    String updateFlg    = (String)lineRow.getAttribute("UpdateFlg"); // �X�V�敪�FN���ƍX�V�s��

    // ********************** //    
    // *   �w�����b�g����   * //
    // ********************** //
    XxwshIndicateLotVOImpl indicateLotVo = getXxwshIndicateLotVO1();
    indicateLotVo.initQuery(
      orderLineId,
      documentTypeCode,
      itemClassCode,
      numOfCases);
    OARow indicateLotRow = (OARow)indicateLotVo.first();
    
    // ���R�[�h�^�C�v��30�F���Ɏ��т��A�w�����b�g���擾�ł��Ȃ������ꍇ
    if (XxwshConstants.RECORD_TYPE_STOC.equals(recordTypeCode) && (lineVo.getRowCount() == 0))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500); 
    } 
    
    // ********************** //    
    // *   ���у��b�g����   * //
    // ********************** //
    XxwshResultLotVOImpl resultLotVo = getXxwshResultLotVO1();
    resultLotVo.initQuery(
      orderLineId,
      documentTypeCode,
      recordTypeCode,
      itemClassCode,
      numOfCases);
    OARow resultLotRow = (OARow)resultLotVo.first();
    
    // �o�^�\���A���у��b�g���Ȃ��ꍇ�A�w�����b�g������
    if (!XxcmnConstants.STRING_N.equals(updateFlg) && (resultLotVo.getRowCount() == 0))
    {
      resultLotVo.initQuery(
        orderLineId,
        documentTypeCode,
        XxwshConstants.RECORD_TYPE_INST,
        itemClassCode,
        numOfCases);
      resultLotRow = (OARow)resultLotVo.first();
    }

    // �o�^�\���A���у��b�g���Ȃ��ꍇ�A��s��\��
    if (!XxcmnConstants.STRING_N.equals(updateFlg) && (resultLotVo.getRowCount() == 0))
    {
      // �f�t�H���g��1�s�\������B
      addRow();
    }
  }
  
  /***************************************************************************
   * �p�����[�^�`�F�b�N���s�����\�b�h�ł��B
   * @param params        - �p�����[�^
   * @throws OAException  - OA��O
   ***************************************************************************
   */
  public void checkParams(HashMap params) throws OAException
  {
    // �p�����[�^�擾
    String callPictureKbn   = (String)params.get("callPictureKbn");   // �ďo��ʋ敪
    String orderLineId      = (String)params.get("orderLineId");      // �󒍖��׃A�h�I��ID
    String headerUpdateDate = (String)params.get("headerUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)params.get("lineUpdateDate");   // ���׍X�V����
    String exeKbn           = (String)params.get("exeKbn");           // �N���敪   

    // �ďo��ʋ敪���ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(callPictureKbn))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_CALL_PICTURE_KBN) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // �󒍖��׃A�h�I��ID���ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(orderLineId))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_ID) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // ���׍X�V�������ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(lineUpdateDate))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }

    // �w�b�_�X�V�������ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(headerUpdateDate))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }
    
    // ���׍X�V�����̏�����YYYY/MM/DD HH24:MI:SS�łȂ��ꍇ
    if(!XxcmnUtility.chkDateFormat(
          getOADBTransaction(),
          lineUpdateDate,
          XxwshConstants.DATE_FORMAT))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_LINE_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13311, 
        tokens);     
    }
    
    // �w�b�_�X�V�����̏�����YYYY/MM/DD HH24:MI:SS�łȂ��ꍇ
    if(!XxcmnUtility.chkDateFormat(
          getOADBTransaction(),
          headerUpdateDate,
          XxwshConstants.DATE_FORMAT))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);
      
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_HEADER_UPDATE_DATE) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13311, 
        tokens);     
    }

    // �ďo��ʋ敪��1:�o�׈˗����͉�ʈȊO�ŁA�N���敪���ݒ肳��Ă��Ȃ��ꍇ
    if (!XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn) && XxcmnUtility.isBlankOrNull(exeKbn))
    {
      // ���ڐ���(�߂�{�^���ȊO��\��
      itemControl(XxcmnConstants.STRING_Y);

      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxwshConstants.TOKEN_PARM_NAME, XxwshConstants.TOKEN_NAME_EXE_KBN) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13310, 
        tokens);        
    }
  }
  
  /***************************************************************************
   * �s�}���������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void addRow()
  {
    // ����VO�擾
    OAViewObject lineVo = getXxwshLineVO1();
    // 1�s�ڂ��擾
    OARow lineRow   = (OARow)lineVo.first();
    // �l�擾
    String lotCtl           = (String)lineRow.getAttribute("LotCtl");           // ���b�g�Ǘ��敪
    String itemClassCode    = (String)lineRow.getAttribute("ItemClassCode");    // �i�ڋ敪
        
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    // ROW�擾
    OARow resultLotRow = (OARow)resultLotVo.createRow();

    // ���b�g�Ǘ��O�i�̏ꍇ
    if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
    {
      // Switcher�̐���
      resultLotRow.setAttribute("LotNoSwitcher" ,            "LotNoDisabled");           // ���b�gNo�F���͕s��
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// �����N�����F���͕s��
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // �ܖ������F���͕s��
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // �ŗL�L���F���͕s��

      // �f�t�H���g�l�̐ݒ�
      resultLotRow.setAttribute("LotId", XxwshConstants.DEFAULT_LOT);    // ���b�gID

    // �i�ڋ敪��5:���i�̏ꍇ
    } else if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
    {
      // Switcher�̐���
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoDisabled");          // ���b�gNo�F���͕s��
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateEnabled");// �����N�����F���͉�
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateEnabled");       // �ܖ������F���͉�
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeEnabled");        // �ŗL�L���F���͉�

    // ����ȊO�̏ꍇ
    } else
    {
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoEnabled");            // ���b�gNo�F���͉�
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// �����N�����F���͕s��
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // �ܖ������F���͕s��
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // �ŗL�L���F���͕s��      
    }
    // �ړ����b�g�ڍׂ̐V�KID�擾
    Number movLotDtlId = XxwshUtility.getMovLotDtlId(getOADBTransaction());
    
    // �f�t�H���g�l�̐ݒ�
    resultLotRow.setAttribute("MovLotDtlId",      movLotDtlId);             // �ړ����b�g�ڍ�ID
    resultLotRow.setAttribute("NewRow",           XxcmnConstants.STRING_Y); // �V�K�s�t���O   
    resultLotRow.setAttribute("ActualQuantity",   new Number(0));           // ���ѐ���DB

    // �V�K�s�}��
    resultLotVo.last();
    resultLotVo.next();
    resultLotVo.insertRow(resultLotRow);
    resultLotRow.setNewRowState(Row.STATUS_INITIALIZED);
  } // addRow
  
  /***************************************************************************
   * ���ڐ�����s�����\�b�h�ł��B
   * @param errFlag   - Y:�G���[�̏ꍇ(�߂�{�^���ȊO�s�\)  N:����
   ***************************************************************************
   */
  public void itemControl(String errFlag)
  {
    // PVO�擾
    OAViewObject pvo = getXxwshShipLotInputPVO1();   
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // �f�t�H���g�l�ݒ�
    pvoRow.setAttribute("ReturnRendered",          Boolean.TRUE); // �x���x����ʂ֖߂�F�\��
    pvoRow.setAttribute("CheckRendered",           Boolean.TRUE); // �`�F�b�N�F�\��
    pvoRow.setAttribute("AddRowRendered",          Boolean.TRUE); // �s�}���F�\��
    pvoRow.setAttribute("GoDisabled",              Boolean.FALSE);// �K�p�F�L��
    pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.FALSE);// ���ʁF�L��

    // �G���[�̏ꍇ(�߂�{�^���ȊO����s�\)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // �`�F�b�N�F��\��
      pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // �s�}���F��\��
      pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // �K�p�F����
      pvoRow.setAttribute("ReturnRendered",          Boolean.FALSE); // �x���x����ʂ֖߂�F��\��
      pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // ���ʁF����

    // �G���[�łȂ��ꍇ      
    } else
    {
      // ����VO�擾
      OAViewObject lineVo = getXxwshLineVO1();
      // ����1�s�ڂ��擾
      OARow lineRow   = (OARow)lineVo.first();
      // �l�擾
      String reqStatus          = (String)lineRow.getAttribute("ReqStatus");          // �X�e�[�^�X
      String amountFixClass     = (String)lineRow.getAttribute("AmountFixClass");     // �L�����z�m��敪
      String shipSupplyCategory = (String)lineRow.getAttribute("ShipSupplyCategory"); // �o�׎x���󕥃J�e�S��
      String lotCtl             = (String)lineRow.getAttribute("LotCtl");             // ���b�g�Ǘ��敪
      String callPictureKbn     = (String)lineRow.getAttribute("CallPictureKbn");     // �ďo��ʋ敪
      String recordTypeCode     = (String)lineRow.getAttribute("RecordTypeCode");     // ���R�[�h�^�C�v

      // ���R�[�h�^�C�v��20:�o�Ɏ��т̏ꍇ
      if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
      {
        // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ̏ꍇ
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
        {
          pvoRow.setAttribute("ReturnRendered", Boolean.FALSE); // �x���x����ʂ֖߂�F��\��

        // �ȉ��̂��Âꂩ�̏ꍇ
        // * �E�ďo��ʋ敪��2:�x���w���쐬���
        // * �E�ďo��ʋ敪��5:���Ɏ��щ��
        // * �E�o�׎x���󕥃J�e�S����05:�L���o�ׂ��A�L�����z�m��敪��1:�m��
        // * �E�o�׎x���󕥃J�e�S����06:�L���ԕi���A�X�e�[�^�X��08:�o�׎��ьv���
        } else if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)  
            || XxwshConstants.CALL_PIC_KBN_STOC.equals(callPictureKbn)
            || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
              && XxwshConstants.AMOUNT_FIX_CLASS_Y.equals(amountFixClass))
            || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET.equals(shipSupplyCategory) 
              && XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus)))
        {
          pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // �`�F�b�N�F��\��
          pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // �s�}���F��\��
          pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // �K�p�F����
          pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // ���ʁF����

          lineRow.setAttribute("UpdateFlg",     XxcmnConstants.STRING_N); // �X�V�敪�FN
        }

      // ���R�[�h�^�C�v��30�F���Ɏ��т̏ꍇ
      } else
      {
        // �ȉ��̂��Âꂩ�̏ꍇ
        // * �E�ďo��ʋ敪��2:�x���w���쐬���
        // * �E�ďo��ʋ敪��4:�o�Ɏ��щ��
        // * �E�o�׎x���󕥃J�e�S����05:�L���o�ׂ��A�L�����z�m��敪��1:�m��
        // * �E�o�׎x���󕥃J�e�S����06:�L���ԕi���A�X�e�[�^�X��08:�o�׎��ьv��� 
        if (XxwshConstants.CALL_PIC_KBN_PROD_CREATE.equals(callPictureKbn)
          || XxwshConstants.CALL_PIC_KBN_DELI.equals(callPictureKbn)
          || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
            && XxwshConstants.AMOUNT_FIX_CLASS_Y.equals(amountFixClass))
          || (XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_RET.equals(shipSupplyCategory)
            && XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus)))
        {
          pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // �`�F�b�N�F��\��
          pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // �s�}���F��\��
          pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // �K�p�F����
          pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // ���ʁF����

          lineRow.setAttribute("UpdateFlg",     XxcmnConstants.STRING_N); // �X�V�敪�FN
        }
      }

      // ���b�g�Ǘ��O�i�̏ꍇ
      if (XxwshConstants.LOT_CTL_N.equals(lotCtl))
      {
        pvoRow.setAttribute("CheckRendered",  Boolean.FALSE); // �`�F�b�N�F��\��
        pvoRow.setAttribute("AddRowRendered", Boolean.FALSE); // �s�}���F��\��
      }      
    }
 }

  /***************************************************************************
   * ���у��b�g�f�[�^��HashMap�Ŏ擾���郁�\�b�h�ł��B
   * @param resultLotRow - ���у��b�gROW
   * @param lineRow      - ����ROW
   * @return HashMap     - ���у��b�gHashMap
   ***************************************************************************
   */
  public HashMap getResultLotHashMap(
    OARow resultLotRow,
    OARow lineRow)
  {
    HashMap ret = new HashMap();
    ret.put("orderLineId",        lineRow.getAttribute("OrderLineId"));           // �󒍖��׃A�h�I��ID
    ret.put("documentTypeCode",   lineRow.getAttribute("DocumentTypeCode"));      // �����^�C�v
    ret.put("recordTypeCode",     lineRow.getAttribute("RecordTypeCode"));        // ���R�[�h�^�C�v
    ret.put("itemId",             lineRow.getAttribute("OpmItemId"));             // �i��ID
    ret.put("itemCode",           lineRow.getAttribute("ItemCode"));              // �i�ڃR�[�h
    ret.put("prodClassCode",      lineRow.getAttribute("ProdClassCode"));         // ���i�敪
    ret.put("itemClassCode",      lineRow.getAttribute("ItemClassCode"));         // �i�ڋ敪
    ret.put("lotId",              resultLotRow.getAttribute("LotId"));            // ���b�gID
    ret.put("lotNo",              resultLotRow.getAttribute("LotNo"));            // ���b�gNo
    ret.put("manufacturedDate",   resultLotRow.getAttribute("ManufacturedDate")); // �����N����
    ret.put("useByDate",          resultLotRow.getAttribute("UseByDate"));        // �ܖ�����
    ret.put("koyuCode",           resultLotRow.getAttribute("KoyuCode"));         // �ŗL�L��
    
    String recordTypeCode = (String)lineRow.getAttribute("RecordTypeCode");
    // ���R�[�h�^�C�v��20:�o�Ɏ��т̏ꍇ
    if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
    {
      ret.put("actualDate",         lineRow.getAttribute("ShippedDate"));         // ���ѓ� = �o�ד�

    //  �������[�h��2�F���Ɏ��т̏ꍇ
    } else
    {
      ret.put("actualDate",         lineRow.getAttribute("ArrivalDate"));         // ���ѓ� = ���ד�
    }

    // ���ѐ��ʎ擾
    // ���Z���ʂ����������l�łȂ��ꍇ�́ANULL
    String convertQuantity = (String)resultLotRow.getAttribute("ConvertQuantity");
    Number numOfCases      = (Number)lineRow.getAttribute("NumOfCases");
    if (!XxcmnUtility.isBlankOrNull(convertQuantity)
      && XxcmnUtility.chkNumeric(convertQuantity, 9, 3)
      && XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
    {
      ret.put("actualQuantity", Double.toString(doConversion(convertQuantity, numOfCases)));  

    } else
    {
      ret.put("actualQuantity", "");
    }

    return ret;
  }

  /***************************************************************************
   * �`�F�b�N�{�^�������������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void checkLot() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap data = new HashMap();

    String apiName   = "checkLot";
    
    // ����VO�擾
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    String callPictureKbn     = (String)lineRow.getAttribute("CallPictureKbn" );    // �ďo��ʋ敪
    String locationRelCode    = (String)lineRow.getAttribute("LocationRelCode");    // ���_���їL���敪
    String shipSupplyCategory = (String)lineRow.getAttribute("ShipSupplyCategory"); // �o�׎x���󕥃J�e�S��
    String lotCtl             = (String)lineRow.getAttribute("LotCtl");             // ���b�g�Ǘ��敪
    String itemClassCode      = (String)lineRow.getAttribute("ItemClassCode");      // �i�ڋ敪
      
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    OARow resultLotRow = null;
    // 1�s��
    resultLotVo.first();

    // ���b�g�Ǘ��敪��1�F���b�g�Ǘ��i�̏ꍇ�̂݃`�F�b�N���s���B
    if (XxwshConstants.LOT_CTL_Y.equals(lotCtl))
    {
      // �S�����[�v
      while (resultLotVo.getCurrentRow() != null)
      {
        // �����Ώۍs���擾
        resultLotRow = (OARow)resultLotVo.getCurrentRow();

        // ********************************** // 
        // *   �`�F�b�N���{���R�[�h����     * //
        // ********************************** //         
        // ���i�̏ꍇ
        if(XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
        {
          // �V�K�s�̏ꍇ�A�\������(���b�gNo)�����Z�b�g
          if (XxcmnConstants.STRING_Y.equals(resultLotRow.getAttribute("NewRow")))
          {
            resultLotRow.setAttribute("LotNo", "");
          }
            
          // �����N�����A�ܖ������A�ŗL�L�����ׂĂɓ��͂̂Ȃ��ꍇ�A�`�F�b�N���s��Ȃ��B
          if (XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("ManufacturedDate"))
            && XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("UseByDate"))
            && XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("KoyuCode")))
          {
            // �������s�킸�ɁA���̃��R�[�h����
            resultLotVo.next();
            continue;
          }
          
        // ���i�ȊO�̏ꍇ
        } else
        {
           // �V�K�s�̏ꍇ�A�\������(�����N�����A�ܖ������A�ŗL�L��)�����Z�b�g
          if (XxcmnConstants.STRING_Y.equals(resultLotRow.getAttribute("NewRow")))
          {
            resultLotRow.setAttribute("ManufacturedDate", "");
            resultLotRow.setAttribute("UseByDate", "");
            resultLotRow.setAttribute("KoyuCode", "");
          }
          
          // ���b�gNo�ɓ��͂̂Ȃ��ꍇ�A�`�F�b�N���s��Ȃ��B
          if (XxcmnUtility.isBlankOrNull(resultLotRow.getAttribute("LotNo")))
          {
            // �������s�킸�ɁA���̃��R�[�h����
            resultLotVo.next();
            continue;
          }
        }
      
        // ���у��b�g�f�[�^HashMap�擾
        data = getResultLotHashMap(resultLotRow, lineRow);

        // ********************************** // 
        // *   ���b�g�}�X�^�Ó����`�F�b�N   * //
        // ********************************** //     
        XxwshUtility.seachOpmLotMst(getOADBTransaction(), data);
        // �l�擾
        String statusDesc       = (String)data.get("statusDesc");       // �X�e�[�^�X�R�[�h����
        String payProvisionRel  = (String)data.get("payProvisionRel");  // �L���x��(����)
        String shipReqRel       = (String)data.get("shipReqRel");       // �o�׈˗�(����)
        String retCode          = (String)data.get("retCode");          // �߂�l
        String lotNo            = (String)data.get("lotNo");            // ���b�gNo
        String koyuCode         = (String)data.get("koyuCode");         // �ŗL�L��
        Number lotId            = (Number)data.get("lotId");            // ���b�gID
        Date   manufacturedDate = null;
        Date   useByDate        = null;
        try
        {       
          if (!XxcmnUtility.isBlankOrNull(data.get("manufacturedDate")))
          {
            manufacturedDate = new Date(data.get("manufacturedDate")); // �����N����          
          }
          if (!XxcmnUtility.isBlankOrNull(data.get("useByDate")))
          {
            useByDate = new Date(data.get("useByDate")); // �ܖ�����          
          }

        // SQL��O�̏ꍇ
        } catch(SQLException s)
        {
            // ���[���o�b�N
            XxwshUtility.rollBack(getOADBTransaction());
            // ���O�o��
            XxcmnUtility.writeLog(
              getOADBTransaction(),
              XxwshConstants.CLASS_AM_XXWSH920001J + XxcmnConstants.DOT + apiName,
              s.toString(),
              6);
            // �G���[���b�Z�[�W�o��
            throw new OAException(
              XxcmnConstants.APPL_XXCMN, 
              XxcmnConstants.XXCMN10123);
        }

        // �߂�l��0�F�ُ�̏ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          // �G���[���b�Z�[�W�p�Ɏ擾���Ȃ����B
          lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ���b�gNo
          // ���b�g���擾�G���[
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "LotNo",
                  lotNo,
                  XxcmnConstants.APPL_XXWSH, 
                  XxwshConstants.XXWSH13312));
                
          // �㑱�������s�킸�ɁA���̃��R�[�h����
          resultLotVo.next();
          continue;
        }

        // ********************************** // 
        // *   ���b�g�X�e�[�^�X�`�F�b�N     * //
        // ********************************** //
        String actualQuantity = (String)data.get("actualQuantity"); // ���Z����
        double actualQuantityD = 0;
        // ���ʂ����͂���Ă���ꍇ�́A���ʂ�double�^�ɕϊ�
        if (!XxcmnUtility.isBlankOrNull(actualQuantity))
        {
          actualQuantityD = Double.parseDouble(actualQuantity);// ���Z���ѐ���                    
        }

        // ���Z���ʂɒl�̂Ȃ��ꍇ�܂��́A���Z���ѐ��ʂ�0�łȂ��ꍇ�̓��b�g�X�e�[�^�X�`�F�b�N���s���B
        if (XxcmnUtility.isBlankOrNull(actualQuantity) || (actualQuantityD != 0))
        {
          // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ��A���_���їL���敪��1:���㋒�_�łȂ��A�o�׈˗�(����)��N:�ΏۊO�̏ꍇ
          if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
            && !XxwshConstants.INCLUDE_EXCLUD_INCLUDE.equals(locationRelCode)
            && XxcmnConstants.STRING_N.equals(shipReqRel))
          {
            // ���b�g�X�e�[�^�X�G���[
            // �G���[���b�Z�[�W�g�[�N���擾
            MessageToken[] tokens = {new MessageToken(XxwshConstants.TOKEN_LOT_STATUS, statusDesc)};      
            // �G���[���b�Z�[�W�擾                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13301,
                    tokens));
                
            // �㑱�������s�킸�ɁA���̃��R�[�h����
            resultLotVo.next();
            continue;
          }

          // �ďo��ʋ敪��1:�o�׈˗����͉�ʈȊO���A�o�׎󕥃J�e�S����05:�L���o�ׂŁA�L���x��(����)��N:�ΏۊO�̏ꍇ
          if (!XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
            && XxwshConstants.AMOUNT_SHIP_SIKYU_RCV_PAY_CTG_CONS_SHIP.equals(shipSupplyCategory)
            && XxcmnConstants.STRING_N.equals(payProvisionRel))
          {
            // ���b�g�X�e�[�^�X�G���[
            // �G���[���b�Z�[�W�g�[�N���擾
            MessageToken[] tokens = {new MessageToken(XxwshConstants.TOKEN_LOT_STATUS, statusDesc)};      
            // �G���[���b�Z�[�W�擾                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13301,
                    tokens));
                
            // �㑱�������s�킸�ɁA���̃��R�[�h����
            resultLotVo.next();
            continue;
          }          
        }
      
        // ********************************** // 
        // *   ���b�g�f�[�^��ROW�ɃZ�b�g    * //
        // ********************************** //
        resultLotRow.setAttribute("LotNo",            lotNo);            // ���b�gNo
        resultLotRow.setAttribute("ManufacturedDate", manufacturedDate); // �����N����
        resultLotRow.setAttribute("UseByDate",        useByDate);        // �ܖ�����
        resultLotRow.setAttribute("KoyuCode",         koyuCode);         // �ŗL�L��
        resultLotRow.setAttribute("LotId",            lotId);            // ���b�gID

        // ���̃��R�[�h��
        resultLotVo.next();
      }

      // ********************************** // 
      // *   ���b�gNo�d���`�F�b�N         * //
      // ********************************** //
      // 1�s��
      resultLotVo.first();
      // �S�����[�v
      while (resultLotVo.getCurrentRow() != null)
      {
        resultLotRow = (OARow)resultLotVo.getCurrentRow();
        // �l�擾
        String lotNo = (String)resultLotRow.getAttribute("LotNo"); // ���b�gNo

        // ���b�gNo�ɒl������ꍇ�̂ݏd���`�F�b�N
        // ���b�gNo��NULL�͏d���Ƃ��Ȃ�
        if (!XxcmnUtility.isBlankOrNull(lotNo))
        {
          // ���b�gNo�̈�v����s���擾
          OAViewObject vo  = getXxwshResultLotVO1();
          Row[] rows = vo.getFilteredRows("LotNo", lotNo);
          OARow row = null;
          // 2�s�ȏ゠��ꍇ�́A�d�����Ă���̂ŃG���[
          if (rows.length > 1)
          { 
            // �d���G���[���b�Z�[�W�擾                          
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13305));
                  
          }          
        }
        // ���̃��R�[�h��
        resultLotVo.next();
      }
   
      // �G���[������ꍇ�A�C�����C�����b�Z�[�W�o��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }
  }

  /***************************************************************************
   * �G���[�`�F�b�N���s�����\�b�h�ł��B
   * @return String - 0:�����Ώۍs�Ȃ� 1:�����Ώۍs����
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String checkError() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap date = new HashMap();
    String entryFlag = "0"; // �����Ώۃt���O

    // ����VO�擾
    OAViewObject lineVo   = getXxwshLineVO1();
    OARow        lineRow  = (OARow)lineVo.first();
    String itemClassCode  = (String)lineRow.getAttribute("ItemClassCode");  // �i�ڋ敪
    String lotCtl         = (String)lineRow.getAttribute("LotCtl");         // ���b�g�Ǘ��敪
    String recordTypeCode = (String)lineRow.getAttribute("RecordTypeCode"); // ���R�[�h�^�C�v

    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    OARow resultLotRow = null;
    // 1�s��
    resultLotVo.first();

    // ************************* //
    // *   �K�{�`�F�b�N        * //
    // ************************* //    
    // �S�����[�v
    while (resultLotVo.getCurrentRow() != null)
    {
      // �����Ώۍs���擾
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ���b�gNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // �����N����
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // �ܖ�����
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // �ŗL�L��
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // ���Z���ѐ���
      
      // ���b�gNo�A�����N�����A�ܖ������A�ŗL�L���A���Z���ѐ��ʂ��ׂĂɓ��͂��Ȃ��ꍇ
      if (isBlankRow(resultLotRow))
      {
        // �������s�킸�ɁA���̃��R�[�h����
        resultLotVo.next();
        continue;
      }
      
      // ���b�g�Ǘ��敪��1�F���b�g�Ǘ��i�̏ꍇ�̂݃��b�g���ړ��̓`�F�b�N���s���B
      if (XxwshConstants.LOT_CTL_Y.equals(lotCtl))
      {
         // �i�ڋ敪��5:���i�̏ꍇ
        if (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
        {
          // �����N�����ɓ��͂��Ȃ��ꍇ
          if (XxcmnUtility.isBlankOrNull(manufacturedDate))
          {
            // �K�{�G���[
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "ManufacturedDate",
                    manufacturedDate,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
          }

          // �ܖ������ɓ��͂��Ȃ��ꍇ
          if (XxcmnUtility.isBlankOrNull(useByDate))
          {
            // �K�{�G���[
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "UseByDate",
                    useByDate,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
          }
      
          // �ŗL�L���ɓ��͂��Ȃ��ꍇ
          if (XxcmnUtility.isBlankOrNull(koyuCode))
          {
            // �K�{�G���[
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "KoyuCode",
                    koyuCode,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
          }

        // �i�ڋ敪��5:���i�ȊO�̏ꍇ 
        } else
        {
          // ���b�gNo�ɓ��͂��Ȃ��ꍇ
          if (XxcmnUtility.isBlankOrNull(lotNo))
          {
            // �K�{�G���[
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXWSH, 
                    XxwshConstants.XXWSH13302));
          }
        }
      }

      // ���Z���ѐ��ʂɓ��͂��Ȃ��ꍇ
      if (XxcmnUtility.isBlankOrNull(convertQuantity))
      {
        // �K�{�G���[
        exceptions.add( 
          new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,          
                resultLotVo.getName(),
                resultLotRow.getKey(),
                "ConvertQuantity",
                convertQuantity,
                XxcmnConstants.APPL_XXWSH, 
                XxwshConstants.XXWSH13302));
                
      // ���Z���ѐ��ʂɓ��͂�����ꍇ
      } else
      {
        // ���l(999999999.999)�łȂ��ꍇ�̓G���[
        if (!XxcmnUtility.chkNumeric(convertQuantity, 9, 3)) 
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXWSH,         
                  XxwshConstants.XXWSH13313));

        // �}�C�i�X�l�̓G���[
        } else if(!XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXWSH,         
                  XxwshConstants.XXWSH13303));
        }
      }

      // �����Ώۃt���OON
      entryFlag = "1";
      
      // ���̃��R�[�h��
      resultLotVo.next();
    }

    // �G���[������ꍇ�A�C�����C�����b�Z�[�W�o��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
    
    // ************************* //
    // *  �݌ɉ�v���ԃ`�F�b�N * //
    // ************************* //
    // ���R�[�h�^�C�v��20:�o�Ɏ��т̏ꍇ
    if (XxwshConstants.RECORD_TYPE_DELI.equals(recordTypeCode))
    {
      Date shippedDate = (Date)lineRow.getAttribute("ShippedDate"); // �o�ד�
      XxwshUtility.chkStockClose(getOADBTransaction(), shippedDate);      
    }

    return entryFlag;
  }

  /***************************************************************************
   * �˗�No���擾���郁�\�b�h�ł��B
   * @param orderLineId  - �󒍖��׃A�h�I��ID
   * @return String      - �˗�No
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String getReqNo(String orderLineId) throws OAException
  {   
    return XxwshUtility.getRequestNo(getOADBTransaction(), orderLineId);
  }

  /***************************************************************************
   * �x���`�F�b�N���s�����\�b�h�ł��B
   * @return HashMap     - �x���G���[���
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap checkWarning() throws OAException
  {
    HashMap msg = new HashMap();

    // ����VO�擾
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    String orderCategoryCode = (String)lineRow.getAttribute("OrderCategoryCode");// �󒍃J�e�S��
    String callPictureKbn    = (String)lineRow.getAttribute("CallPictureKbn");   // �ďo��ʋ敪
    Number orderLineId       = (Number)lineRow.getAttribute("OrderLineId");      // �󒍖��׃A�h�I��ID
    Number opmItemId         = (Number)lineRow.getAttribute("OpmItemId");        // OPM�i��ID
    String itemCode          = (String)lineRow.getAttribute("ItemCode");         // �i�ڃR�[�h
    String itemName          = (String)lineRow.getAttribute("ItemName");         // �i�ږ�
    Number numOfCases        = (Number)lineRow.getAttribute("NumOfCases");       // �P�[�X����
    String reqStatus         = (String)lineRow.getAttribute("ReqStatus");        // �X�e�[�^�X
    String prodClassCode     = (String)lineRow.getAttribute("ProdClassCode");    // ���i�敪
    String itemClassCode     = (String)lineRow.getAttribute("ItemClassCode");    // �i�ڋ敪
    String resultDeliverTo   = (String)lineRow.getAttribute("ResultDeliverTo");  // �o�א�(�R�[�h)
    String subinventoryName  = (String)lineRow.getAttribute("SubinventoryName"); // �ۊǑq�ɖ�
    Number resultDeliverToId = (Number)lineRow.getAttribute("ResultDeliverToId");// �o�א�_����ID
    Number deliverFromId     = (Number)lineRow.getAttribute("DeliverFromId");    // �o�׌�ID
    Date   shippedDate       = (Date)  lineRow.getAttribute("ShippedDate");      // �o�ד�
    Date   scheduleShipDate  = (Date)  lineRow.getAttribute("ScheduleShipDate"); // �o�ח\���
    String documentTypeCode  = (String)lineRow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String recordTypeCode    = (String)lineRow.getAttribute("RecordTypeCode");   // ���R�[�h�^�C�v
    String lotCtl            = (String)lineRow.getAttribute("LotCtl");           // ���b�g�Ǘ��敪
        
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    OARow resultLotRow = null;

    // �x�����i�[�p
    String[]  lotRevErrFlgRow = new String[resultLotVo.getRowCount()]; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    String[]  minusErrFlgRow  = new String[resultLotVo.getRowCount()]; // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O   
    String[]  exceedErrFlgRow = new String[resultLotVo.getRowCount()]; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
    String[]  itemNameRow     = new String[resultLotVo.getRowCount()]; // �i�ږ�
    String[]  lotNoRow        = new String[resultLotVo.getRowCount()]; // ���b�gNo
    String[]  deliveryRow     = new String[resultLotVo.getRowCount()]; // �o�א�(�R�[�h)
    String[]  revDateRow      = new String[resultLotVo.getRowCount()]; // �t�]���t
    String[]  manuDateRow     = new String[resultLotVo.getRowCount()]; // �����N����
    String[]  koyuCodeRow     = new String[resultLotVo.getRowCount()]; // �ŗL�L��
    String[]  stockRow        = new String[resultLotVo.getRowCount()]; // �莝����
    String[]  warehouseRow    = new String[resultLotVo.getRowCount()]; // �ۊǑq�ɖ�

    // 1�s��
    resultLotVo.first();

    // �󒍃J�e�S����ORDER:�󒍂̏ꍇ�̂݌x���`�F�b�N���s���B
    if (XxwshConstants.ORDER_CATEGORY_CODE_ORDER.equals(orderCategoryCode))
    {
      // �S�����[�v
      while (resultLotVo.getCurrentRow() != null)
      {
        // �����Ώۍs���擾
        resultLotRow = (OARow)resultLotVo.getCurrentRow();
        Number lotId            = (Number)resultLotRow.getAttribute("LotId");            // ���b�gID
        String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ���b�gNo
        Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // �����N����
        Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // �ܖ�����
        String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // �ŗL�L��
        String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // ���Z����        

        // ���b�gNo�A�����N�����A�ܖ������A�ŗL�L���A���Z���ѐ��ʂ��ׂĂɓ��͂��Ȃ��ꍇ
        if (isBlankRow(resultLotRow))
        {
          // �������s�킸�ɁA���̃��R�[�h����
          resultLotVo.next();
          continue;
        }
      
        // �x���G���[�p
        lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
        minusErrFlgRow [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
        exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
        itemNameRow    [resultLotVo.getCurrentRowIndex()] = itemName;         // �i�ږ�
        lotNoRow       [resultLotVo.getCurrentRowIndex()] = lotNo;            // ���b�gNo
        deliveryRow    [resultLotVo.getCurrentRowIndex()] = resultDeliverTo;  // �o�א於��
        revDateRow     [resultLotVo.getCurrentRowIndex()] = "";               // �t�]���t
        manuDateRow    [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // �����N����
        koyuCodeRow    [resultLotVo.getCurrentRowIndex()] = koyuCode;         // �ŗL�L��
        stockRow       [resultLotVo.getCurrentRowIndex()] = "";               // �莝����
        warehouseRow   [resultLotVo.getCurrentRowIndex()] = subinventoryName; // �ۊǑq�ɖ�     

        // *************************** //
        // *  ���b�g�t�]�h�~�`�F�b�N * //
        // *************************** //
        // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ��A���b�g�Ǘ��敪��1�F���b�g�Ǘ��i�̏ꍇ�̂�
        // ���b�g�t�]�h�~�`�F�b�N���s���B
        if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn)
          && XxwshConstants.LOT_CTL_Y.equals(lotCtl))
        {
          // * �ȉ��̏����ɓ��Ă͂܂�ꍇ�A�`�F�b�N���s���B
          // * �E�X�e�[�^�X��03:���ߍ�
          // * �E(���i�敪��2:�h�����N���A�i�ڋ敪��5:���i) �܂��� 
          // *   (���i�敪��1:���[�t���A�i�ڋ敪��(4:�����i �܂��� 5:���i))
          // * �E�����N������NULL�łȂ�
          if (XxwshConstants.TRANSACTION_STATUS_CLOSE.equals(reqStatus)
            && (XxwshConstants.PROD_CLASS_CODE_DRINK.equals(prodClassCode)
                && XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode))
              || (XxwshConstants.PROD_CLASS_CODE_LEAF .equals(prodClassCode)
                && (XxwshConstants.ITEM_TYPE_PROD.equals(itemClassCode)
                  || XxwshConstants.ITEM_TYPE_HALF.equals(itemClassCode)))
            && !XxcmnUtility.isBlankOrNull(manufacturedDate))
          {
            // ���b�g�t�]�h�~�`�F�b�N
            HashMap data = XxwshUtility.doCheckLotReversal(
                            getOADBTransaction(),
                            itemCode,
                            lotNo,
                            resultDeliverToId,
                            shippedDate);

            Number result  = (Number)data.get("result");  // ��������
            Date   revDate = (Date)  data.get("revDate"); // �t�]���t

            // API���s���ʂ�1:�G���[�̏ꍇ
            if (XxwshConstants.RETURN_NOT_EXE.equals(result))
            {
              // ���b�g�t�]�h�~�G���[�t���O��Y�ɐݒ�
              lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
              revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // �t�]���t
            }
          }
        }

        // ******************************** //
        // * �莝�݌ɐ��ʁE�����\���擾 * //
        // ******************************** //
        // �莝�݌ɐ��ʎZ�oAPI���s
        Number stockQyt = XxwshUtility.getStockQty(
                            getOADBTransaction(),
                            deliverFromId,
                            opmItemId,
                            lotId,
                            lotCtl);
        // �x���G���[�p
        stockRow[resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(stockQyt); // �莝����
        
        // �����\���Z�oAPI���s
        Number canEncQty = XxwshUtility.getCanEncQty(
                             getOADBTransaction(),
                             deliverFromId,
                             opmItemId,
                             lotId,
                             lotCtl);

        double stockQtyD       = XxcmnUtility.doubleValue(stockQyt);        // �莝�݌ɐ���
        double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // �����\��
        double actualQtyInputD = doConversion(convertQuantity, numOfCases); // ���ѐ���(���͒l)
        
        // �X�e�[�^�X��04:�o�׎��ьv��ς܂��́A08:�o�׎��ьv��� �̏ꍇ
        if (XxwshConstants.TRANSACTION_STATUS_ADD.equals(reqStatus)
          || XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus))
        {
          double resultActualQtyD = 0;
          // ���у��b�g������ꍇ�́A�o�^�ώ��у��b�g���擾
          if (XxwshUtility.checkMovLotDtl(
                getOADBTransaction(),
                orderLineId,           // �󒍖��׃A�h�I��ID
                documentTypeCode,      // �����^�C�v
                recordTypeCode,        // ���R�[�h�^�C�v
                lotId))                // ���b�gID
          {
            // ���ѐ���(���у��b�g)�擾
            resultActualQtyD = XxcmnUtility.doubleValue(
                                 XxwshUtility.getActualQuantity(
                                   getOADBTransaction(),
                                   orderLineId,           // �󒍖��׃A�h�I��ID
                                   documentTypeCode,      // �����^�C�v
                                   recordTypeCode,        // ���R�[�h�^�C�v
                                   lotId));               // ���b�gID
          }

          // ���ѐ���(���у��b�g) < ���ѐ���(���͒l) (�o�^�ώ��ѐ��ʂ�葽���o�^����ꍇ)�̂݃`�F�b�N�s��
          if (resultActualQtyD < actualQtyInputD)
          {
            // *************************** //
            // *   �}�C�i�X�݌Ƀ`�F�b�N  * //
            // *************************** //
            // �莝�݌ɐ��� - (���ѐ���(���͒l) - ���ѐ���(���у��b�g))��0��菬�����Ȃ�ꍇ�A�x��
            if ((stockQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
            {
              // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O��Y�ɐݒ�
              minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;              
            }
            // ********************************* //
            // *   �����\�݌ɐ����߃`�F�b�N  * //
            // ********************************* //
            // �����\�� - (���ѐ���(���͒l) - ���ѐ���(���у��b�g))��0��菬�����Ȃ�ꍇ�A�x��
            if ((canEncQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
            {
              // �����\�݌ɐ����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
              exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
            }
          }
          
        // �X�e�[�^�X��04:�o�׎��ьv��ς܂��́A08:�o�׎��ьv��ςłȂ��ꍇ
        } else
        {
          // *************************** //
          // *   �}�C�i�X�݌Ƀ`�F�b�N  * //
          // *************************** //
          // �莝�݌ɐ��� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ
          if ((stockQtyD - actualQtyInputD) < 0)
          {
            // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O��Y�ɐݒ�
            minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }

          // ********************************* //
          // *   �����\�݌ɐ����߃`�F�b�N  * //
          // ********************************* //
          // �w�����b�g������ꍇ
          if (XxwshUtility.checkMovLotDtl(
                getOADBTransaction(),
                orderLineId,                     // �󒍖��׃A�h�I��ID
                documentTypeCode,                // �����^�C�v
                XxwshConstants.RECORD_TYPE_INST, // ���R�[�h�^�C�v 10:�w��
                lotId))                          // ���b�gID
          {
            // ���ѐ���(�w�����b�g)�擾
            double indicateActualQtyD = XxcmnUtility.doubleValue(
                                           XxwshUtility.getActualQuantity(
                                             getOADBTransaction(),
                                             orderLineId,                     // �󒍖��׃A�h�I��ID
                                             documentTypeCode,                // �����^�C�v
                                             XxwshConstants.RECORD_TYPE_INST, // ���R�[�h�^�C�v 10:�w��
                                             lotId));                         // ���b�gID

            // * �ȉ��̏������ׂĂɓ��Ă͂܂�ꍇ
            // * �E�o�ח\��� > �o�ד� (�O�|���ŏo�ׂ����ꍇ)
            // * �E�����\�� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ 
            if (XxcmnUtility.chkCompareDate(1, scheduleShipDate, shippedDate)
              && ((canEncQtyD - actualQtyInputD) < 0))
            {
              // �����\�݌ɐ����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
              exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;

            // * �ȉ��̏������ׂĂɓ��Ă͂܂�ꍇ
            // * �E���ѐ���(�w�����b�g) < ���ѐ���(���͒l) (�w�����b�g��葽���o�^����ꍇ)
            // * �E�����\�� - (���ѐ���(���͒l) - ���ѐ���(�w�����b�g)) ��0��菬�����Ȃ�ꍇ
            } else if ((indicateActualQtyD < actualQtyInputD) 
                 && ((canEncQtyD - (actualQtyInputD - indicateActualQtyD)) < 0))
            {
              // �����\�݌ɐ����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
              exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
            }

          // �w�����b�g���Ȃ��ꍇ
          } else
          {
            // �����\�� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ
            if ((canEncQtyD - actualQtyInputD) < 0)
            {
              // �����\�݌ɐ����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
              exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
            }            
          }        
        }
        // ���̃��R�[�h��
        resultLotVo.next();
      }
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow); // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    msg.put("minusErrFlg",      (String[])minusErrFlgRow);  // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow); // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
    msg.put("itemName",         (String[])itemNameRow);     // �i�ږ�
    msg.put("lotNo",            (String[])lotNoRow);        // ���b�gNo
    msg.put("delivery",         (String[])deliveryRow);     // �o�א�(�R�[�h)
    msg.put("revDate",          (String[])revDateRow);      // �t�]���t
    msg.put("manufacturedDate", (String[])manuDateRow);     // �����N����
    msg.put("koyuCode",         (String[])koyuCodeRow);     // �ŗL�L��
    msg.put("stock",            (String[])stockRow);        // �莝����
    msg.put("warehouseName",    (String[])warehouseRow);    // �ۊǑq�ɖ�

    return msg;
  }

  /***************************************************************************
   * ���ѐ��ʂɊ��Z���郁�\�b�h�ł��B
   * @param convertQuantity - ���Z����
   * @param numOfCases      - �P�[�X����
   * @return double         - ���ѐ���
   ***************************************************************************
   */
  public double doConversion(
    String convertQuantity,
    Number numOfCases)
  {
    double convertQuantityD = Double.parseDouble(convertQuantity); // ���Z����
    double actualQuantityD  = 0; // ���ѐ���
    double numOfCasesD      = XxcmnUtility.doubleValue(numOfCases); // �P�[�X����

    // ���ѐ��� = ���Z���� * �P�[�X����
    return convertQuantityD * numOfCasesD;
  }

 /*****************************************************************************
   * �o�׎��у��b�g�̓o�^�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ****************************************************************************/
  public void entryShipData() throws OAException
  {    
    // ***************************** //
    // *  ���b�N�擾�E�r���`�F�b�N * //
    // ***************************** //
    getLockAndChkExclusive();

    // ����VO�擾
    OAViewObject lineVo     = getXxwshLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");
    Number orderLineNumber  = (Number)lineRow.getAttribute("OrderLineNumber"); // ����No
    String reqStatus        = (String)lineRow.getAttribute("ReqStatus");       // �X�e�[�^�X
    String requestNo        = (String)lineRow.getAttribute("RequestNo");       // �˗�No
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // ���R�[�h�^�C�v
    String callPictureKbn   = (String)lineRow.getAttribute("CallPictureKbn");  // �ďo��ʋ敪
    String exeKbn           = (String)lineRow.getAttribute("ExeKbn");          // �N���敪
// 2008-07-23 H.Itou ADD START
    String actualConfirmClass = (String)lineRow.getAttribute("ActualConfirmClass"); // ���ьv��ϋ敪
// 2008-07-23 H.Itou ADD END
    Number newOrderHeaderId = null;
    Number newOrderLineId   = null;

    String actualQtySum = null;

    // �X�e�[�^�X��04 �o�׎��ьv��� OR 08 �o�׎��ьv��� �̏ꍇ
// 2008-06-13 H.Itou MOD START 04 �o�׎��ьv��ς��A�w�b�_�ɕR�t���o�׎��ѐ��ʂ����ׂēo�^�ς̏ꍇ�ɕύX
    if ((XxwshConstants.TRANSACTION_STATUS_ADD.equals(reqStatus)
      && XxwshUtility.checkShippedQuantityEntry(getOADBTransaction(), orderHeaderId))
// 2008-06-13 H.Itou MOD END
      || XxwshConstants.XXPO_TRANSACTION_STATUS_ADD.equals(reqStatus))
    {
// 2008-07-23 H.Itou ADD START
      // ���ьv��ϋ敪��Y�̏ꍇ�̂݁A�R�s�[�������s
      if (XxcmnConstants.STRING_Y.equals(actualConfirmClass))
      {
// 2008-07-23 H.Itou ADD END
// 2008-07-23 H.Itou MOD START
        // ************************* //
        // *  �󒍏��R�s�[����   * //
        // ************************* //
        // ���т����łɌv��ςȂ̂ŁA�������c�����߁A�R�s�[����B
        newOrderHeaderId = XxwshUtility.copyOrderData(
                             getOADBTransaction(),
                             orderHeaderId);      

        // **************************** //
        // *  �ŐV�󒍖���ID�擾����  * //
        // **************************** //
        newOrderLineId = XxwshUtility.getOrderLineId(
                           getOADBTransaction(),
                           newOrderHeaderId,
                           orderLineNumber);

        lineRow.setAttribute("OrderHeaderId", newOrderHeaderId); // �ŐV�̎󒍃w�b�_�A�h�I��ID
        lineRow.setAttribute("OrderLineId",   newOrderLineId);   // �ŐV�̎󒍖��׃A�h�I��ID

// 2008-07-23 H.Itou MOD END
// 2008-07-23 H.Itou ADD START
      // ���ьv��ϋ敪��Y�łȂ��ꍇ
      } else
      {
        // �R�s�[���������Ȃ��̂ŁAID�͕ύX�Ȃ�
        newOrderHeaderId = orderHeaderId;
        newOrderLineId   = orderLineId;
      }
// 2008-07-23 H.Itou ADD END
      
      // ******************************** //
      // *  �ړ����b�g�ڍ׎��ѓo�^����  * //
      // ******************************** //
      insertResultLot();

      // ********************** // 
      // *  ���ѐ��ʍ��v�擾  * //
      // ********************** //
      actualQtySum = XxwshUtility.getActualQuantitySum(
                       getOADBTransaction(),
                       newOrderLineId,
                       documentTypeCode,
                       recordTypeCode);
      
      // ****************************************** // 
      // *  �󒍖��׃A�h�I���o�׎��ѐ��ʍX�V����  * //
      // ****************************************** //
      XxwshUtility.updateShippedQuantity(
        getOADBTransaction(),
        newOrderLineId,
        actualQtySum);
      
      // *********************** // 
      // *  �o�׎��ьv�㏈��   * //
      // *********************** //
      doShippedResultAdd(requestNo, callPictureKbn);
      
    //�X�e�[�^�X��04 �o�׎��ьv��� OR 08 �o�׎��ьv��� �ȊO�̏ꍇ
    } else
    {    
      // ******************************** //
      // *  �ړ����b�g�ڍ׎��ѓo�^����  * //
      // ******************************** //
      insertResultLot();

      // ********************** // 
      // *  ���ѐ��ʍ��v�擾  * //
      // ********************** //
      actualQtySum = XxwshUtility.getActualQuantitySum(
                       getOADBTransaction(),
                       orderLineId,
                       documentTypeCode,
                       recordTypeCode);
                     
      // ****************************************** // 
      // *  �󒍖��׃A�h�I���o�׎��ѐ��ʍX�V����  * //
      // ****************************************** //
      XxwshUtility.updateShippedQuantity(
        getOADBTransaction(),
        orderLineId,
        actualQtySum);
    
      // �󒍖��׃A�h�I���̏o�׎��ѐ��ʂ����ׂēo�^�ς̏ꍇ
      if (XxwshUtility.checkShippedQuantityEntry(getOADBTransaction(), orderHeaderId))
      {       
        // ****************************************** // 
        // *  �󒍃w�b�_�A�h�I���X�e�[�^�X�X�V����  * //
        // ****************************************** //
        updateReqStatusAdd(orderHeaderId, callPictureKbn);

        // *********************** // 
        // *  �o�׎��ьv�㏈��   * //
        // *********************** //
        doShippedResultAdd(requestNo, callPictureKbn);

      }
      
      // �R�s�[���������Ȃ��̂ŁAID�͕ύX�Ȃ�
      newOrderHeaderId = orderHeaderId;
      newOrderLineId   = orderLineId;
    }

    // ***************** //
    // *  �R�~�b�g     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());
      
    // ******************** // 
    // *  �ŏI�X�V������  * //
    // ******************** //
    // �󒍃w�b�_�ŏI�X�V���擾
    String headerUpdateDate = XxwshUtility.getOrderHeaderUpdateDate(
                                getOADBTransaction(),
                                newOrderHeaderId);
    // �󒍖��׍ŏI�X�V���擾
    String lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                                getOADBTransaction(),
                                newOrderHeaderId);

    // ******************** // 
    // *  �ĕ\��          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("orderLineId",      XxcmnUtility.stringValue(newOrderLineId));
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    params.put("recordTypeCode",   recordTypeCode);
    initialize(params);

    // **************************** // 
    // *  �o�^�������b�Z�[�W�o��  * //
    // **************************** //
    throw new OAException(
      XxcmnConstants.APPL_XXWSH,
      XxwshConstants.XXWSH33304, 
      null, 
      OAException.INFORMATION, 
      null);
    
  }

 /*****************************************************************************
   * ���Ɏ��у��b�g�̓o�^�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ****************************************************************************/
  public void entryStockData() throws OAException
  {    
    // ***************************** //
    // *  ���b�N�擾�E�r���`�F�b�N * //
    // ***************************** //
    getLockAndChkExclusive();

    // ����VO�擾
    OAViewObject lineVo     = getXxwshLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();

    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");     // �󒍃w�b�_�A�h�I��ID
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");       // �󒍖��׃A�h�I��ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");  // �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");    // ���R�[�h�^�C�v
    String callPictureKbn   = (String)lineRow.getAttribute("CallPictureKbn");    // �ďo��ʋ敪
    String exeKbn           = (String)lineRow.getAttribute("ExeKbn");            // �N���敪   
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate");  // �w�b�_�X�V��
    
    String actualQtySum = null;

    // ******************************** //
    // *  �ړ����b�g�ڍ׎��ѓo�^����  * //
    // ******************************** //
    insertResultLot();

    // ********************** // 
    // *  ���ѐ��ʍ��v�擾  * //
    // ********************** //
    actualQtySum = XxwshUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     orderLineId,
                     documentTypeCode,
                     recordTypeCode);
                   
    // ****************************************** // 
    // *  �󒍖��׃A�h�I�����Ɏ��ѐ��ʍX�V����  * //
    // ****************************************** //
    XxwshUtility.updateShipToQuantity(
      getOADBTransaction(),
      orderLineId,
      actualQtySum);

    // ***************** //
    // *  �R�~�b�g     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());
      
    // ******************** // 
    // *  �ŏI�X�V������  * //
    // ******************** //
    // �󒍖��׍ŏI�X�V���擾
    String lineUpdateDate   = XxwshUtility.getOrderLineUpdateDate(
                                getOADBTransaction(),
                                orderHeaderId);

    // ******************** // 
    // *  �ĕ\��          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("orderLineId",      XxcmnUtility.stringValue(orderLineId));
    params.put("callPictureKbn",   callPictureKbn);
    params.put("headerUpdateDate", headerUpdateDate);
    params.put("lineUpdateDate",   lineUpdateDate);
    params.put("exeKbn",           exeKbn);
    params.put("recordTypeCode",   recordTypeCode);
    initialize(params);

    // **************************** // 
    // *  �o�^�������b�Z�[�W�o��  * //
    // **************************** //
    throw new OAException(
      XxcmnConstants.APPL_XXWSH,
      XxwshConstants.XXWSH33304, 
      null, 
      OAException.INFORMATION, 
      null);
    
  }
  
 /*****************************************************************************
  * ���b�N���擾���A�r���`�F�b�N���s�����\�b�h�ł��B
  * @throws OAException - OA��O
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // ����VO�擾
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    Number orderHeaderId    = (Number)lineRow.getAttribute("OrderHeaderId");    // �󒍃w�b�_�A�h�I��ID
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");      // �󒍖��׃A�h�I��ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // ���R�[�h�^�C�v
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)lineRow.getAttribute("LineUpdateDate");   // ���׍X�V����

    String retCode = null;
    String headerUpdateDateDb = null; // �󒍃w�b�_�ŏI�X�V��
    String lineUpdateDateDb   = null; // �󒍖��׍ŏI�X�V��

    // ******************************** //
    // *   �󒍃w�b�_�A�h�I�����b�N   * //
    // ******************************** //
    HashMap orderHeaderRet = XxwshUtility.getXxwshOrderHeadersAllLock(
                               getOADBTransaction(),
                               orderHeaderId);
    retCode            = (String)orderHeaderRet.get("retFlag");        // �߂�l
    headerUpdateDateDb = (String)orderHeaderRet.get("lastUpdateDate"); // �ŏI�X�V��
    // ���b�N�G���[�̏ꍇ
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
          XxcmnConstants.APPL_XXWSH, 
          XxwshConstants.XXWSH13306);
    }

    // ******************************** //
    // *   �󒍖��׃A�h�I�����b�N   * //
    // ******************************** //
    HashMap orderLineRet = XxwshUtility.getXxwshOrderLinesAllLock(
                             getOADBTransaction(),
                             orderHeaderId);
    retCode          = (String)orderLineRet.get("retFlag");        // �߂�l
    lineUpdateDateDb = (String)orderLineRet.get("lastUpdateDate"); // �ŏI�X�V��
    // ���b�N�G���[�̏ꍇ
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13306);
    }

    // *********************************** //
    // *  �ړ����b�g�ڍ׃A�h�I�����b�N   * //
    // *********************************** //
    retCode = XxwshUtility.getXxinvMovLotDetailsLock(
                getOADBTransaction(),
                orderLineId,           // �󒍖��׃A�h�I��ID
                documentTypeCode,      // �����^�C�v
                recordTypeCode);       // ���R�[�h�^�C�v

    // ���b�N�G���[�̏ꍇ
    if (XxcmnConstants.RETURN_ERR1.equals(retCode))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13306);
    }
    // ******************************** //
    // *   �󒍃w�b�_�r���`�F�b�N     * //
    // ******************************** //
    // ���b�N���Ɏ擾�����ŏI�X�V���Ɣ�r
    if (!headerUpdateDateDb.equals(headerUpdateDate))
    {
// 2008-06-27 H.Itou Mod Start
      // �������g�̃R���J�����g�N���ɂ��X�V���ꂽ�ꍇ�͔r���G���[�Ƃ��Ȃ�
      if (!XxwshUtility.isOrderHdrUpdForOwnConc(
             getOADBTransaction(),
             orderHeaderId,
             XxwshConstants.CONC_NAME_XXWSH420001C))
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(getOADBTransaction());
        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10147);        
      }
// 2008-06-27 H.Itou Mod End
    }

    // ******************************** //
    // *   �󒍖��הr���`�F�b�N       * //
    // ******************************** //
    // ���b�N���Ɏ擾�����ŏI�X�V���Ɣ�r
    if (!lineUpdateDateDb.equals(lineUpdateDate))
    {
// 2008-06-27 H.Itou Mod Start
      // �������g�̃R���J�����g�N���ɂ��X�V���ꂽ�ꍇ�͔r���G���[�Ƃ��Ȃ�
      if (!XxwshUtility.isOrderLineUpdForOwnConc(
             getOADBTransaction(),
             orderHeaderId,
             XxwshConstants.CONC_NAME_XXWSH420001C))
      {
        // ���[���o�b�N
        XxwshUtility.rollBack(getOADBTransaction());
        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
          XxcmnConstants.APPL_XXCMN, 
          XxcmnConstants.XXCMN10147);       
      }
// 2008-06-27 H.Itou Mod End
    }    
  }

  /***************************************************************************
   * �ړ����b�g�ڍׂ̎��ѓo�^�A���эX�V�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void insertResultLot() throws OAException
  {
    // ����VO�擾
    OAViewObject lineVo  = getXxwshLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number orderLineId      = (Number)lineRow.getAttribute("OrderLineId");      // �󒍖��׃A�h�I��ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // ���R�[�h�^�C�v
      
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxwshResultLotVO1();
    resultLotVo.first();
    OARow resultLotRow = null;
      
    // �S�����[�v
    while (resultLotVo.getCurrentRow() != null)
    {
      resultLotRow = (OARow)resultLotVo.getCurrentRow();
      Number lotId            = (Number)resultLotRow.getAttribute("LotId");            // ���b�gID
      String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ���b�gNo
      Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // �����N����
      Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // �ܖ�����
      String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // �ŗL�L��
      String convertQuantity  = (String)resultLotRow.getAttribute("ConvertQuantity");  // ���Z���ѐ���

      // ���b�gNo�A�����N�����A�ܖ������A�ŗL�L���A���Z���ѐ��ʂ��ׂĂɓ��͂��Ȃ��ꍇ
      if (isBlankRow(resultLotRow))
      {
        // �������s�킸�ɁA���̃��R�[�h����
        resultLotVo.next();
        continue;
      }

      // ���у��b�g�f�[�^HashMap�擾
      HashMap data = getResultLotHashMap(resultLotRow, lineRow);
      
      // ���у��b�g���o�^�ς̏ꍇ(���эX�V��)
      if (XxwshUtility.checkMovLotDtl(
            getOADBTransaction(),
            orderLineId,           // �󒍖��׃A�h�I��ID
            documentTypeCode,      // �����^�C�v
            recordTypeCode,        // ���R�[�h�^�C�v
            lotId))                // ���b�gID
      {    
        // ******************************************** // 
        // *  �ړ����b�g�ڍ׃A�h�I�����ѐ��ʍX�V����  * //
        // ******************************************** //
        XxwshUtility.updateActualQuantity(getOADBTransaction(), data);
        
      // ���у��b�g���o�^�ςłȂ��ꍇ(���ѐV�K��)
      } else
      {       
        // ************************************ // 
        // *  �ړ����b�g�ڍ׃A�h�I���o�^����  * //
        // ************************************ //       
        XxwshUtility.insertXxinvMovLotDetails(getOADBTransaction(), data);          

      }
      // ���̃��R�[�h��
      resultLotVo.next();
    }
  }

  /***************************************************************************
   * �󒍃w�b�_�A�h�I���X�e�[�^�X���o�׎��ьv��ςɍX�V���郁�\�b�h�ł��B
   * @param  orderHeaderId   - �󒍃w�b�_�A�h�I��ID
   * @param  callPictureKbn  - �ďo��ʋ敪
   * @throws OAException     - OA��O
   ***************************************************************************
   */
  public void updateReqStatusAdd(
    Number orderHeaderId,
    String callPictureKbn)
  throws OAException
  {
    String reqStatus = null; // �X�e�[�^�X
    
    // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      reqStatus = XxwshConstants.TRANSACTION_STATUS_ADD; // �X�e�[�^�X 04 �o�׎��ьv���

    // ����ȊO�̏ꍇ(�x�����)�̏ꍇ
    } else
    {
      reqStatus = XxwshConstants.XXPO_TRANSACTION_STATUS_ADD; // �X�e�[�^�X 08 �o�׎��ьv���
    }

    XxwshUtility.updateReqStatus(
      getOADBTransaction(),
      orderHeaderId,
      reqStatus);
  }

  /***************************************************************************
   * �o�׎��ьv�㏈��(�d�ʗe�Ϗ����X�V�E�o�׈˗�/�o�׎��э쐬)���s�����\�b�h�ł��B
   * @param  requestNo         - �˗�No
   * @param  callPictureKbn    - �ďo��ʋ敪
   * @throws OAException       - OA��O
   ***************************************************************************
   */
  public void doShippedResultAdd(
    String requestNo,
    String callPictureKbn)
  throws OAException
  {
    String reqStatus = null; // �X�e�[�^�X
    String bizType   = null; // �Ɩ����

    // �ďo��ʋ敪��1:�o�׈˗����͉�ʂ̏ꍇ
    if (XxwshConstants.CALL_PIC_KBN_SHIP_INPUT.equals(callPictureKbn))
    {
      reqStatus = XxwshConstants.TRANSACTION_STATUS_ADD; // �X�e�[�^�X 04 �o�׎��ьv���
      bizType   = XxcmnConstants.BIZ_TYPE_WSH;           // �Ɩ����    1 �o��

    // ����ȊO�̏ꍇ(�x�����)�̏ꍇ
    } else
    {
      reqStatus = XxwshConstants.XXPO_TRANSACTION_STATUS_ADD; // �X�e�[�^�X 08 �o�׎��ьv���
      bizType = XxcmnConstants.BIZ_TYPE_PROV;                 // �Ɩ����    2 �x��
    }
        
    // ********************************** // 
    // *  �d�ʗe�Ϗ������X�V�`�F�b�N  * //
    // ********************************** //
    Number ret = XxwshUtility.doUpdateLineItems(getOADBTransaction(), bizType, requestNo);
    // �d�ʗe�Ϗ����X�V�֐��̖߂�l��1�F�G���[�̏ꍇ
    if (XxwshConstants.RETURN_NOT_EXE.equals(ret))
    {
      // ���[���o�b�N
      XxwshUtility.rollBack(getOADBTransaction());
      // �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXWSH, 
        XxwshConstants.XXWSH13308);
    }

    // ***************** //
    // *  �R�~�b�g     * //
    // ***************** //
    XxwshUtility.commit(getOADBTransaction());

    // *********************************************** // 
    // *  �o�׈˗�/�o�׎��э쐬�����R���J�����g�ďo  * //
    // *********************************************** //
    XxwshUtility.doShipRequestAndResultEntry(getOADBTransaction(), requestNo);
  }

  /***************************************************************************
   * ��s�������ǂ����𔻒肷�郁�\�b�h�ł��B
   * @param  row         - �Ώۍs
   * @return boolean     - true  : ���͍��ڂ����ׂ�NULL  false : ���͍��ڂ�NULL�łȂ�
   ***************************************************************************
   */
  public boolean isBlankRow(OARow row)
  {
    String lotNo            = (String)row.getAttribute("LotNo");            // ���b�gNo
    Date   manufacturedDate = (Date)  row.getAttribute("ManufacturedDate"); // �����N����
    Date   useByDate        = (Date)  row.getAttribute("UseByDate");        // �ܖ�����
    String koyuCode         = (String)row.getAttribute("KoyuCode");         // �ŗL�L��
    String convertQuantity  = (String)row.getAttribute("ConvertQuantity");  // ���Z���ѐ���
      
    // ���b�gNo�A�����N�����A�ܖ������A�ŗL�L���A���Z���ѐ��ʂ��ׂĂɓ��͂��Ȃ��ꍇ
    if ((XxcmnUtility.isBlankOrNull(lotNo))
      && (XxcmnUtility.isBlankOrNull(manufacturedDate))
      && (XxcmnUtility.isBlankOrNull(useByDate))
      && (XxcmnUtility.isBlankOrNull(koyuCode))
      && (XxcmnUtility.isBlankOrNull(convertQuantity)))
    {
      return true;

    // ���Âꂩ�ɓ��͂���̏ꍇ
    } else
    {
      return false;
    }
  }
  
  /**
   * 
   * Container's getter for XxwshLineVO1
   */
  public XxwshLineVOImpl getXxwshLineVO1()
  {
    return (XxwshLineVOImpl)findViewObject("XxwshLineVO1");
  }

  /**
   * 
   * Container's getter for XxwshIndicateLotVO1
   */
  public XxwshIndicateLotVOImpl getXxwshIndicateLotVO1()
  {
    return (XxwshIndicateLotVOImpl)findViewObject("XxwshIndicateLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshResultLotVO1
   */
  public XxwshResultLotVOImpl getXxwshResultLotVO1()
  {
    return (XxwshResultLotVOImpl)findViewObject("XxwshResultLotVO1");
  }

  /**
   * 
   * Container's getter for XxwshShipLotInputPVO1
   */
  public XxwshShipLotInputPVOImpl getXxwshShipLotInputPVO1()
  {
    return (XxwshShipLotInputPVOImpl)findViewObject("XxwshShipLotInputPVO1");
  }


  
}