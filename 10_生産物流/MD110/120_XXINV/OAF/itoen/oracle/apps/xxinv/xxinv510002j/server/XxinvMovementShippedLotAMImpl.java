/*============================================================================
* �t�@�C���� : XxinvMovementShippedLotAMImpl
* �T�v����   : �o�ɁE���Ƀ��b�g���׉�ʃA�v���P�[�V�������W���[��
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-11 1.0  �ɓ��ЂƂ�     �V�K�쐬
* 2008-07-10 1.1  �ɓ��ЂƂ�     �����ύX ���g�̃R���J�����g�R�[���ŕύX�����ꍇ�A�r���G���[�Ƃ��Ȃ��B
* 2008-07-14 1.2  �R�{  ���v     �����ύX �d�ʗe�Ϗ������֐��̃R�[���^�C�~���O�̕ύX
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510002j.server;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxinv.util.XxinvConstants;
import itoen.oracle.apps.xxinv.util.XxinvUtility;

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
 * �o�Ƀ��b�g���׉�ʃA�v���P�[�V�������W���[���ł��B
 * @author  ORACLE �ɓ��ЂƂ�
 * @version 1.1
 ***************************************************************************
 */
public class XxinvMovementShippedLotAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementShippedLotAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxinv.xxinv510002j.server", "XxinvMovementShippedLotAMLocal");
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
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();   
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
    // *   �\���f�[�^�擾    * //
    // *********************** //
    doSearch(params);
    
    // *********************** //
    // *      ���ڐ���       * //
    // *********************** //
    itemControl(XxcmnConstants.STRING_N);
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
    String movLineId        = (String)params.get("movLineId");      // �ړ�����ID
    String productFlg       = (String)params.get("productFlg");     // ���i���ʋ敪
    String documentTypeCode = XxinvConstants.DOC_TYPE_MOVE;         // �����^�C�v 20:�ړ�
    String recordTypeCode   = (String)params.get("recordTypeCode"); // ���R�[�h�^�C�v 20:�o�Ɏ��� 30:���Ɏ���
    String updateFlag       = (String)params.get("updateFlag");

    // ********************** //    
    // *   ���׌���         * //
    // ********************** //
    XxinvLineVOImpl lineVo = getXxinvLineVO1();
    lineVo.initQuery(
      movLineId,
      productFlg);
      
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
    lineRow.setAttribute("ProductFlg",        productFlg);        // ���i���ʋ敪
    lineRow.setAttribute("DocumentTypeCode",  documentTypeCode);  // �����^�C�v
    lineRow.setAttribute("RecordTypeCode",    recordTypeCode);    // ���R�[�h�^�C�v
    lineRow.setAttribute("UpdateFlag",    updateFlag);
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");     // ���b�g�Ǘ��敪
    Number numOfCases = (Number)lineRow.getAttribute("NumOfCases"); // �P�[�X����

    // ********************** //    
    // *   �w�����b�g����   * //
    // ********************** //
    XxinvIndicateLotVOImpl indicateLotVo = getXxinvIndicateLotVO1();
    indicateLotVo.initQuery(movLineId, productFlg, lotCtl, numOfCases);
    // 1�s�ڂ��擾
    OARow indicateLotRow = (OARow)indicateLotVo.first();

    // ********************** //    
    // *   ���у��b�g����   * //
    // ********************** //
    XxinvResultLotVOImpl resultLotVo = getXxinvResultLotVO1();
    resultLotVo.initQuery(
      movLineId,
      productFlg,
      recordTypeCode,
      lotCtl,
      numOfCases);
    OARow resultLotRow = (OARow)resultLotVo.first();

    // ���у��b�g���擾�ł��Ȃ������ꍇ�A�w�����b�g������
    if (resultLotVo.getRowCount() == 0)
    {
      resultLotVo.initQuery(
        movLineId,
        productFlg,
        XxinvConstants.RECORD_TYPE_10,
        lotCtl,
        numOfCases);
      resultLotRow = (OARow)resultLotVo.first();
    } else
    {
      // PVO�擾
      OAViewObject pvo = getXxInvMovementShippedLotPVO1();
      // PVO1�s�ڂ��擾
      OARow pvoRow = (OARow)pvo.first();
      // ���b�g�t�]�`�F�b�N�s�v�t���O�ݒ�
      pvoRow.setAttribute("lotRevNotExe", "1");
    }

    // �擾�ł��Ȃ������ꍇ�A�f�t�H���g��1�s�\������B
    if (resultLotVo.getRowCount() == 0)
    {
      addRow();
    }
  }

  /***************************************************************************
   * ���ڐ�����s�����\�b�h�ł��B
   * @param  errFlag   - Y:�G���[�̏ꍇ(�߂�{�^���ȊO�s�\)  N:����
   ***************************************************************************
   */
  public void itemControl(String errFlag)
  {
    // PVO�擾
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();   
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // �f�t�H���g�l�ݒ�
    pvoRow.setAttribute("CheckRendered",           Boolean.TRUE);  // �`�F�b�N�F�\��
    pvoRow.setAttribute("AddRowRendered",          Boolean.TRUE);  // �s�}���F�\��
    pvoRow.setAttribute("ReturnDisabled",          Boolean.FALSE); // ����F�L��
    pvoRow.setAttribute("GoDisabled",              Boolean.FALSE); // �K�p�F�L��
    pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.FALSE); // ���ʁF�L��

    // �G���[�̏ꍇ(�߂�{�^���ȊO����s�\)
    if (XxcmnConstants.STRING_Y.equals(errFlag))
    {
      pvoRow.setAttribute("CheckRendered",           Boolean.FALSE); // �`�F�b�N�F��\��
      pvoRow.setAttribute("AddRowRendered",          Boolean.FALSE); // �s�}���F��\��
      pvoRow.setAttribute("ReturnDisabled",          Boolean.TRUE);  // ����F����
      pvoRow.setAttribute("GoDisabled",              Boolean.TRUE ); // �K�p�F����
      pvoRow.setAttribute("ConvertQuantityReadOnly", Boolean.TRUE);  // ���ʁF����

    // �G���[�łȂ��ꍇ      
    } else
    {
      // ����VO�擾
      OAViewObject lineVo = getXxinvLineVO1();
      // ����1�s�ڂ��擾
      OARow lineRow   = (OARow)lineVo.first();
      String lotCtl   = (String)lineRow.getAttribute("LotCtl"); // ���b�g�Ǘ��敪

      // ���b�g�Ǘ��O�i�̏ꍇ
      if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
      {
        pvoRow.setAttribute("CheckRendered",  Boolean.FALSE); // �`�F�b�N�F��\��
        pvoRow.setAttribute("AddRowRendered", Boolean.FALSE); // �s�}���F��\��
      }      
    }
 }  
 
  /***************************************************************************
   * �s�}���������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void addRow()
  {
    // ����VO�擾
    OAViewObject lineVo = getXxinvLineVO1();
    // 1�s�ڂ��擾
    OARow lineRow   = (OARow)lineVo.first();
    String productFlg = (String)lineRow.getAttribute("ProductFlg"); // ���i���ʋ敪
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");     // ���b�g�Ǘ��敪
      
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    // ROW�擾
    OARow resultLotRow = (OARow)resultLotVo.createRow();

    // ���b�g�Ǘ��O�i�̏ꍇ
    if (XxinvConstants.LOT_CTL_N.equals(lotCtl))
    {
      // Switcher�̐���
      resultLotRow.setAttribute("LotNoSwitcher" ,            "LotNoDisabled");           // ���b�gNo�F���͕s��
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// �����N�����F���͕s��
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // �ܖ������F���͕s��
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // �ŗL�L���F���͕s��

      // �f�t�H���g�l�̐ݒ�
      resultLotRow.setAttribute("LotId", XxinvConstants.DEFAULT_LOT);    // ���b�gID

    // ���i���ʋ敪��1:���i�̏ꍇ
    } else if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
    {
      // Switcher�̐���
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoDisabled");          // ���b�gNo�F���͕s��
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateEnabled");// �����N�����F���͉�
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateEnabled");       // �ܖ������F���͉�
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeEnabled");        // �ŗL�L���F���͉�

    // ���i���ʋ敪��2:���i�ȊO�̏ꍇ
    } else
    {
      resultLotRow.setAttribute("LotNoSwitcher",             "LotNoEnabled");            // ���b�gNo�F���͉�
      resultLotRow.setAttribute("ManufacturedDateSwitcher",  "ManufacturedDateDisabled");// �����N�����F���͕s��
      resultLotRow.setAttribute("UseByDateSwitcher",         "UseByDateDisabled");       // �ܖ������F���͕s��
      resultLotRow.setAttribute("KoyuCodeSwitcher",          "KoyuCodeDisabled");        // �ŗL�L���F���͕s��      
    }
    // �ړ����b�g�ڍׂ̐V�KID�擾
    Number movLotDtlId = XxinvUtility.getMovLotDtlId(getOADBTransaction());
    
    // �f�t�H���g�l�̐ݒ�
    resultLotRow.setAttribute("MovLotDtlId", movLotDtlId);             // �ړ����b�g�ڍ�ID
    resultLotRow.setAttribute("NewRow",      XxcmnConstants.STRING_Y); // �V�K�s�t���O   

    // �V�K�s�}��
    resultLotVo.last();
    resultLotVo.next();
    resultLotVo.insertRow(resultLotRow);
    resultLotRow.setNewRowState(Row.STATUS_INITIALIZED);
  } // addRow

  /***************************************************************************
   * �`�F�b�N�{�^�������������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void checkLot() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);

    String apiName   = "checkLot";
    
    // ����VO�擾
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    String productFlg = (String)lineRow.getAttribute("ProductFlg" ); // ���i���ʋ敪
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");      // ���b�g�Ǘ��敪
    Number itemId     = (Number)lineRow.getAttribute("ItemId");      // �i��ID
      
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;
    // 1�s��
    resultLotVo.first();

    // ���b�g�Ǘ��敪��1�F���b�g�Ǘ��i�̏ꍇ�̂݃`�F�b�N���s���B
    if (XxinvConstants.LOT_CTL_Y.equals(lotCtl))
    {
      // �S�����[�v
      while (resultLotVo.getCurrentRow() != null)
      {
        // �����Ώۍs���擾
        resultLotRow = (OARow)resultLotVo.getCurrentRow();

        // ********************************** // 
        // *   �`�F�b�N���{���R�[�h����     * //
        // ********************************** //
        // ���i���ʋ敪��1:���i�̏ꍇ
        if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
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

        // ********************************** // 
        // *   ���b�g�}�X�^�Ó����`�F�b�N   * //
        // ********************************** //
        String lotNo            = (String)resultLotRow.getAttribute("LotNo");            // ���b�gNo
        Date   manufacturedDate = (Date)  resultLotRow.getAttribute("ManufacturedDate"); // �����N����
        Date   useByDate        = (Date)  resultLotRow.getAttribute("UseByDate");        // �ܖ�����
        String koyuCode         = (String)resultLotRow.getAttribute("KoyuCode");         // �ŗL�L��
        String movInstRel       = null;
        String statusDesc       = null;
        String retCode          = null;
        Number lotId            = null;
        String stock_quantity   = null;
        HashMap ret = XxinvUtility.seachOpmLotMst(
                        getOADBTransaction(),
                        lotNo,
                        manufacturedDate,
                        useByDate,
                        koyuCode,
                        itemId,
                        productFlg);

        // �߂�l�f�[�^���擾
        lotNo            = (String)ret.get("lotNo");      // ���b�gNo
        manufacturedDate = null;                          // �����N����
        useByDate        = null;                          // �ܖ�����
        koyuCode         = (String)ret.get("koyuCode");   // �ŗL�L��
        retCode          = (String)ret.get("retCode");    // �߂�l
        lotId            = (Number)ret.get("lotId");      // ���b�gID
        movInstRel       = (String)ret.get("movInstRel"); // �ړ��w��(����)
        statusDesc       = (String)ret.get("statusDesc"); // �X�e�[�^�X�R�[�h����
        stock_quantity   = (String)ret.get("stock_quantity"); // �݌ɓ���
 
        try
        {
          if (!XxcmnUtility.isBlankOrNull(ret.get("manufacturedDate")))
          {
            manufacturedDate = new Date(ret.get("manufacturedDate")); // �����N����          
          }
          if (!XxcmnUtility.isBlankOrNull(ret.get("useByDate")))
          {
            useByDate = new Date(ret.get("useByDate")); // �ܖ�����          
          }

        // SQL��O�̏ꍇ
        } catch(SQLException s)
        {
          // ���[���o�b�N
          XxinvUtility.rollBack(getOADBTransaction());
          // ���O�o��
          XxcmnUtility.writeLog(
            getOADBTransaction(),
            XxinvConstants.CLASS_XXINV_UTILITY + XxcmnConstants.DOT + apiName,
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
          // ���b�g���擾�G���[
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "LotNo",
                  (String)resultLotRow.getAttribute("LotNo"),
                  XxcmnConstants.APPL_XXINV, 
                  XxinvConstants.XXINV10033));
                
          // �㑱�������s�킸�ɁA���̃��R�[�h����
          resultLotVo.next();
          continue;
        }

        // ********************************** // 
        // *   ���b�g�X�e�[�^�X�`�F�b�N     * //
        // ********************************** //
        String actualQuantity = (String)resultLotRow.getAttribute("ConvertQuantity"); // ���Z����
        double actualQuantityD = 0;
        // ���ʂ����͂���Ă���ꍇ�́A���ʂ�double�^�ɕϊ�
        if (!XxcmnUtility.isBlankOrNull(actualQuantity))
        {
          actualQuantityD = Double.parseDouble(actualQuantity);// ���Z���ѐ���                    
        }
        // ���Z���ʂɒl�̂Ȃ��ꍇ�܂��́A���Z���ѐ��ʂ�0�łȂ��ꍇ�̓��b�g�X�e�[�^�X�`�F�b�N���s���B
        if (XxcmnUtility.isBlankOrNull(actualQuantity) || (actualQuantityD != 0))
        {
          // �ړ��w��(����)��N:�ΏۊO�̏ꍇ
          if (XxcmnConstants.STRING_N.equals(movInstRel))
          {
            // ���b�g�X�e�[�^�X�G���[
            // �G���[���b�Z�[�W�g�[�N���擾
            MessageToken[] tokens = {new MessageToken(XxinvConstants.TOKEN_LOT_STATUS, statusDesc)};
            // �G���[���b�Z�[�W�擾                            
            exceptions.add( 
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,          
                    resultLotVo.getName(),
                    resultLotRow.getKey(),
                    "LotNo",
                    lotNo,
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10165,
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
        resultLotRow.setAttribute("StockQuantity",    stock_quantity);   // �݌ɓ���

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
          OAViewObject vo  = getXxinvResultLotVO1();
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
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10129));
                  
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
   * @return String    ����:TRUE�A�ُ�:FALSE
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String checkError() throws OAException
  {
    ArrayList exceptions = new ArrayList(100);
    HashMap date = new HashMap();
    String ret = XxcmnConstants.STRING_TRUE;
    int i = 0;

    // ����VO�擾
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    String productFlg = (String)lineRow.getAttribute("ProductFlg" ); // ���i���ʋ敪
    String lotCtl     = (String)lineRow.getAttribute("LotCtl");      // ���b�g�Ǘ��敪

    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
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
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl))
      {
        // ���i���ʋ敪��1:���i�̏ꍇ
        if (XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg))
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
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
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
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
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
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
          }

        // ���i���ʋ敪��1:���i�ȊO�̏ꍇ
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
                    XxcmnConstants.APPL_XXINV, 
                    XxinvConstants.XXINV10128));
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
                XxcmnConstants.APPL_XXINV, 
                XxinvConstants.XXINV10128));
                
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
                  XxcmnConstants.APPL_XXINV,         
                  XxinvConstants.XXINV10160));

        // �}�C�i�X�l�̓G���[
        } else if (!XxcmnUtility.chkCompareNumeric(2, convertQuantity, "0"))
        {
          exceptions.add( 
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,          
                  resultLotVo.getName(),
                  resultLotRow.getKey(),
                  "ConvertQuantity",
                  convertQuantity,
                  XxcmnConstants.APPL_XXINV,         
                  XxinvConstants.XXINV10030));
        }
      }
      i++;
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
    Date actualShipDate    = (Date)lineRow.getAttribute("ActualShipDate");    // �o�Ɏ��ѓ�
    Date actualArrivalDate = (Date)lineRow.getAttribute("ActualArrivalDate"); // ���Ɏ��ѓ�

    // �o�Ɏ��ѓ����N���[�Y���Ă���ꍇ
    if (XxinvUtility.chkStockClose(getOADBTransaction(), actualShipDate))
    {
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE) };
      // �݌Ɋ��ԃG���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXINV, 
        XxinvConstants.XXINV10120, 
        tokens);  
    }

    // ���Ɏ��ѓ����N���[�Y���Ă���ꍇ
    if (XxinvUtility.chkStockClose(getOADBTransaction(), actualArrivalDate))
    {
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE) };
      // �݌Ɋ��ԃG���[���b�Z�[�W�o��
      throw new OAException(
        XxcmnConstants.APPL_XXINV, 
        XxinvConstants.XXINV10120, 
        tokens);  
    }

    if (i == 0)
    {
      ret = XxcmnConstants.STRING_FALSE;
    }
    return ret;
  }

  /***************************************************************************
   * ��s�������ǂ����𔻒肷�郁�\�b�h�ł��B
   * @param row          - �Ώۍs
   * @return boolean     - true  : ���͍��ڂ����ׂ�NULL  false : ���͍��ڂ�NULL�łȂ�
   * @throws OAException - OA��O
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
    if (XxcmnUtility.isBlankOrNull(lotNo)
      && XxcmnUtility.isBlankOrNull(manufacturedDate)
      && XxcmnUtility.isBlankOrNull(useByDate)
      && XxcmnUtility.isBlankOrNull(koyuCode)
      && XxcmnUtility.isBlankOrNull(convertQuantity))
    {
      return true;

    // ���Âꂩ�ɓ��͂���̏ꍇ
    } else
    {
      return false;
    }
  }

  /***************************************************************************
   * �o�Ƀ��b�g��ʂ̌x���`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap checkWarningShipped() throws OAException
  {
    HashMap msg = new HashMap();

    // ����VO�擾
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId           = (Number)lineRow.getAttribute("MovLineId");          // �ړ�����ID
    Number itemId              = (Number)lineRow.getAttribute("ItemId");             // �i��ID
    String itemCode            = (String)lineRow.getAttribute("ItemCode");           // �i�ڃR�[�h
    String itemName            = (String)lineRow.getAttribute("ItemName");           // �i�ږ�
    Number numOfCases          = (Number)lineRow.getAttribute("NumOfCases");         // �P�[�X����
    Number shipToLocatId       = (Number)lineRow.getAttribute("ShipToLocatId");      // ���ɐ�ID
    String shipToLocatCode     = (String)lineRow.getAttribute("ShipToLocatCode");    // ���ɐ�R�[�h
    String shippedLocatName    = (String)lineRow.getAttribute("ShippedLocatName");   // �o�Ɍ��ۊǑq�ɖ�
    Number shippedLocatId      = (Number)lineRow.getAttribute("ShippedLocatId");     // �o�Ɍ�ID    
    Date   actualShipDate      = (Date)  lineRow.getAttribute("ActualShipDate");     // �o�Ɏ��ѓ�
    Date   actualArrivalDate   = (Date)  lineRow.getAttribute("ActualArrivalDate");  // ���Ɏ��ѓ�
    Date   scheduleShipDate    = (Date)  lineRow.getAttribute("ScheduleShipDate");   // �o�ɗ\���
    Date   scheduleArrivalDate = (Date)  lineRow.getAttribute("ScheduleArrivalDate");// ���ɗ\���
    String lotCtl              = (String)lineRow.getAttribute("LotCtl");             // ���b�g�Ǘ��敪
    String status              = (String)lineRow.getAttribute("Status");             // �X�e�[�^�X
    String recordTypeCode      = (String)lineRow.getAttribute("RecordTypeCode");     // ���R�[�h�^�C�v 20:�o�Ɏ���
    String documentTypeCode    = (String)lineRow.getAttribute("DocumentTypeCode");   // �����^�C�v
    String productFlg          = (String)lineRow.getAttribute("ProductFlg");         // ���i���ʋ敪
        
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;

    // �x�����i�[�p
    String[]  lotRevErrFlgRow   = new String[resultLotVo.getRowCount()]; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    String[]  minusErrFlgRow    = new String[resultLotVo.getRowCount()]; // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O   
    String[]  exceedErrFlgRow   = new String[resultLotVo.getRowCount()]; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
    String[]  itemNameRow       = new String[resultLotVo.getRowCount()]; // �i�ږ�
    String[]  lotNoRow          = new String[resultLotVo.getRowCount()]; // ���b�gNo
    String[]  shipToLocCodeRow  = new String[resultLotVo.getRowCount()]; // ���ɐ�R�[�h
    String[]  revDateRow        = new String[resultLotVo.getRowCount()]; // �t�]���t
    String[]  manuDateRow       = new String[resultLotVo.getRowCount()]; // �����N����
    String[]  koyuCodeRow       = new String[resultLotVo.getRowCount()]; // �ŗL�L��
    String[]  stockRow          = new String[resultLotVo.getRowCount()]; // �莝����
    String[]  shippedLocNameRow = new String[resultLotVo.getRowCount()]; // �o�Ɍ��ۊǑq�ɖ�

    // 1�s��
    resultLotVo.first();

    // PVO�擾
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // ���b�g�t�]�`�F�b�N�s�v�t���O�擾
    String lotRevNotExe = (String)pvoRow.getAttribute("lotRevNotExe");

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
      lotRevErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
      minusErrFlgRow   [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
      exceedErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �����\�݌ɐ����߃`�F�b�N�G���[�t���O   
      itemNameRow      [resultLotVo.getCurrentRowIndex()] = itemName;         // �i�ږ�
      lotNoRow         [resultLotVo.getCurrentRowIndex()] = lotNo;            // ���b�gNo
      shipToLocCodeRow [resultLotVo.getCurrentRowIndex()] = shipToLocatCode;  // ���ɐ�R�[�h
      revDateRow       [resultLotVo.getCurrentRowIndex()] = new String();     // �t�]���t
      manuDateRow      [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // �����N����
      koyuCodeRow      [resultLotVo.getCurrentRowIndex()] = koyuCode;         // �ŗL�L��
      stockRow         [resultLotVo.getCurrentRowIndex()] = new String();     // �莝����
      shippedLocNameRow[resultLotVo.getCurrentRowIndex()] = shippedLocatName; // �o�Ɍ��ۊǑq�ɖ�     

      // *************************** //
      // *  ���b�g�t�]�h�~�`�F�b�N * //
      // *************************** //
      // * �ȉ��̏����ɓ��Ă͂܂�ꍇ�A�`�F�b�N���s���B
      // * �E���b�g�Ǘ��敪��1�F���b�g�Ǘ��i
      // * �E���b�g�t�]�`�F�b�N�s�v�t���O��Null
      // * �E���i���ʋ敪��1:���i
      // * �E�X�e�[�^�X��02:�˗��ρ@03:������  05:���ɕ񍐗L�̂��Âꂩ
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl)
        && XxcmnUtility.isBlankOrNull(lotRevNotExe)
          && XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg)
          && (XxinvConstants.STATUS_02.equals(status)
            || XxinvConstants.STATUS_03.equals(status)
            || XxinvConstants.STATUS_05.equals(status)))
      {
        Date standardDate = null;
        // ���Ɏ��ѓ���NULL�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
        {
          standardDate = scheduleArrivalDate; // ���ɗ\�����K�p���Ƃ���B
          
        // ���Ɏ��ѓ����łȂ��ꍇ
        } else
        {
          standardDate = actualArrivalDate;   // ���Ɏ��ѓ���K�p���Ƃ���B
        }
        // ���b�g�t�]�h�~�`�F�b�N
        HashMap data = XxinvUtility.doCheckLotReversal(
                         getOADBTransaction(),
                         itemCode,
                         lotNo,
                         shipToLocatId,
                         standardDate);

        Number result  = (Number)data.get("result");  // ��������
        Date   revDate = (Date)  data.get("revDate"); // �t�]���t

        // API���s���ʂ�1:�G���[�̏ꍇ
        if (XxinvConstants.RETURN_NOT_EXE.equals(result))
        {
          // ���b�g�t�]�h�~�G���[�t���O��Y�ɐݒ�
          lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // �t�]���t
        }
      }

      // ******************************** //
      // * �莝�݌ɐ��ʁE�����\���擾 * //
      // ******************************** //
      // �莝�݌ɐ��ʎZ�oAPI���s
      Number stockQyt = XxinvUtility.getStockQty(
                          getOADBTransaction(),
                          shippedLocatId,
                          itemId,
                          lotId,
                          lotCtl);
      // �x���G���[�p
      stockRow[resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(stockQyt); // �莝����
        
      // �����\���Z�oAPI���s
      Number canEncQty = XxinvUtility.getCanEncQty(
                           getOADBTransaction(),
                           shippedLocatId,
                           itemId,
                           lotId,
                           lotCtl);

      double stockQtyD       = XxcmnUtility.doubleValue(stockQyt);        // �莝�݌ɐ���
      double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // �����\��
      double actualQtyInputD = doConversion(convertQuantity, numOfCases); // ���ѐ���(���͒l)

      // �X�e�[�^�X��04�F�o�ɕ񍐗L OR 06�F���o�ɕ񍐗L�̏ꍇ
      if (XxinvConstants.STATUS_04.equals(status) || XxinvConstants.STATUS_06.equals(status))
      {
        double resultActualQtyD = 0;
        // ���у��b�g������ꍇ
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // �ړ�����ID
              documentTypeCode,              // �����^�C�v
              recordTypeCode,                // ���R�[�h�^�C�v
              lotId))                        // ���b�gID
        {
          // ���ѐ���(���у��b�g)�擾
          resultActualQtyD = XxcmnUtility.doubleValue(
                               XxinvUtility.getActualQuantity(
                                 getOADBTransaction(),
                                 movLineId,             // �ړ�����ID
                                 documentTypeCode,      // �����^�C�v
                                 recordTypeCode,        // ���R�[�h�^�C�v
                                 lotId));               // ���b�gID
        }
        // ���ѐ���(���у��b�g) < ���ѐ���(���͒l) (���ѐ��ʂ𑝂₵�ēo�^����)�ꍇ�̂݃`�F�b�N�s��
        if (resultActualQtyD < actualQtyInputD)
        {
          // ********************************* //
          // *   �����\�݌ɐ����߃`�F�b�N  * //
          // ********************************* //
          // �����\�� - (���ѐ���(���͒l) - ���ѐ���(���у��b�g))��0��菬�����Ȃ�ꍇ�A�x��
          if ((canEncQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
          {
            // �����\�݌ɐ����߃`�F�b�N�G���[�t���O��Y�ɐݒ�
            exceedErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }

          // *************************** //
          // *   �}�C�i�X�݌Ƀ`�F�b�N  * //
          // *************************** //
          // �莝�݌ɐ��� - (���ѐ���(���͒l) - ���ѐ���(���у��b�g))��0��菬�����Ȃ�ꍇ�A�x��
          if ((stockQtyD - (actualQtyInputD - resultActualQtyD)) < 0)
          {
            // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O��Y�ɐݒ�
            minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;              
          }
        }
          
      // �X�e�[�^�X��02�F�˗��� OR 03�F������ OR 05�F���ɕ񍐗L�̏ꍇ
      } else if (XxinvConstants.STATUS_02.equals(status)
          || XxinvConstants.STATUS_03.equals(status) 
          || XxinvConstants.STATUS_05.equals(status))
      { 
        // ********************************* //
        // *   �����\�݌ɐ����߃`�F�b�N  * //
        // ********************************* //
        // �w�����b�g������ꍇ
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // �ړ�����ID
              documentTypeCode,              // �����^�C�v
              XxinvConstants.RECORD_TYPE_10, // ���R�[�h�^�C�v 10:�w��
              lotId))                        // ���b�gID
        {
          // ���ѐ���(�w�����b�g)�擾
          double indicateActualQtyD = XxcmnUtility.doubleValue(
                                         XxinvUtility.getActualQuantity(
                                           getOADBTransaction(),
                                           movLineId,                     // �ړ�����ID
                                           documentTypeCode,              // �����^�C�v
                                           XxinvConstants.RECORD_TYPE_10, // ���R�[�h�^�C�v 10:�w��
                                           lotId));                       // ���b�gID

          // * �ȉ��̏������ׂĂɓ��Ă͂܂�ꍇ
          // * �E�o�ɗ\��� > �o�Ɏ��ѓ� (�O�|���ŏo�ׂ����ꍇ)
          // * �E�����\�� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ 
          if (XxcmnUtility.chkCompareDate(1, scheduleShipDate, actualShipDate)
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

        // *************************** //
        // *   �}�C�i�X�݌Ƀ`�F�b�N  * //
        // *************************** //
        // �莝�݌ɐ��� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ
        if ((stockQtyD - actualQtyInputD) < 0)
        {
          // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O��Y�ɐݒ�
          minusErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
        }
      }

      // ���̃��R�[�h��
      resultLotVo.next();
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);  // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    msg.put("minusErrFlg",      (String[])minusErrFlgRow);   // �}�C�i�X�݌Ƀ`�F�b�N�G���[�t���O 
    msg.put("exceedErrFlg",     (String[])exceedErrFlgRow);  // �����\�݌ɐ����߃`�F�b�N�G���[�t���O
    msg.put("itemName",         (String[])itemNameRow);      // �i�ږ�
    msg.put("lotNo",            (String[])lotNoRow);         // ���b�gNo
    msg.put("shipToLocCode",    (String[])shipToLocCodeRow); // ���ɐ�R�[�h
    msg.put("revDate",          (String[])revDateRow);       // �t�]���t
    msg.put("manufacturedDate", (String[])manuDateRow);      // �����N����
    msg.put("koyuCode",         (String[])koyuCodeRow);      // �ŗL�L��
    msg.put("stock",            (String[])stockRow);         // �莝����
    msg.put("shippedLocName",   (String[])shippedLocNameRow);// �o�ɐ�ۊǑq�ɖ�

    return msg;
  }

  /***************************************************************************
   * ���Ƀ��b�g��ʂ̌x���`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public HashMap checkWarningShipTo() throws OAException
  {
    HashMap msg = new HashMap();

    // ����VO�擾
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId           = (Number)lineRow.getAttribute("MovLineId");          // �ړ�����ID
    Number itemId              = (Number)lineRow.getAttribute("ItemId");             // �i��ID
    String itemCode            = (String)lineRow.getAttribute("ItemCode");           // �i�ڃR�[�h
    String itemName            = (String)lineRow.getAttribute("ItemName");           // �i�ږ�
    Number numOfCases          = (Number)lineRow.getAttribute("NumOfCases");         // �P�[�X����
    Number shipToLocatId       = (Number)lineRow.getAttribute("ShipToLocatId");      // ���ɐ�ID
    String shipToLocatCode     = (String)lineRow.getAttribute("ShipToLocatCode");    // ���ɐ�R�[�h
    String shipToLocatName     = (String)lineRow.getAttribute("ShipToLocatName");    // ���Ɍ��ۊǑq�ɖ�
    Date   actualArrivalDate   = (Date)  lineRow.getAttribute("ActualArrivalDate");  // ���Ɏ��ѓ�
    Date   scheduleArrivalDate = (Date)  lineRow.getAttribute("ScheduleArrivalDate");// ���ɗ\���
    String lotCtl              = (String)lineRow.getAttribute("LotCtl");             // ���b�g�Ǘ��敪
    String status              = (String)lineRow.getAttribute("Status");             // �X�e�[�^�X
    String recordTypeCode      = (String)lineRow.getAttribute("RecordTypeCode");     // ���R�[�h�^�C�v 30:���Ɏ���
    String documentTypeCode    = (String)lineRow.getAttribute("DocumentTypeCode");   // �����^�C�v
    String productFlg          = (String)lineRow.getAttribute("ProductFlg");         // ���i���ʋ敪
        
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
    OARow resultLotRow = null;

    // �x�����i�[�p
    String[]  lotRevErrFlgRow   = new String[resultLotVo.getRowCount()]; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    String[]  shortageErrFlgRow = new String[resultLotVo.getRowCount()]; // �����\�݌ɐ��s���`�F�b�N�G���[�t���O   
    String[]  itemNameRow       = new String[resultLotVo.getRowCount()]; // �i�ږ�
    String[]  lotNoRow          = new String[resultLotVo.getRowCount()]; // ���b�gNo
    String[]  shipToLocCodeRow  = new String[resultLotVo.getRowCount()]; // ���ɐ�R�[�h
    String[]  revDateRow        = new String[resultLotVo.getRowCount()]; // �t�]���t
    String[]  manuDateRow       = new String[resultLotVo.getRowCount()]; // �����N����
    String[]  koyuCodeRow       = new String[resultLotVo.getRowCount()]; // �ŗL�L��
    String[]  shipToLocNameRow  = new String[resultLotVo.getRowCount()]; // �o�Ɍ��ۊǑq�ɖ�

    // 1�s��
    resultLotVo.first();

    // PVO�擾
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // ���b�g�t�]�`�F�b�N�s�v�t���O�擾
    String lotRevNotExe = (String)pvoRow.getAttribute("lotRevNotExe");

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
      lotRevErrFlgRow  [resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
      shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_N; // �����\�݌ɐ��s���`�F�b�N�G���[�t���O   
      itemNameRow      [resultLotVo.getCurrentRowIndex()] = itemName;                // �i�ږ�
      lotNoRow         [resultLotVo.getCurrentRowIndex()] = lotNo;                   // ���b�gNo
      shipToLocCodeRow [resultLotVo.getCurrentRowIndex()] = shipToLocatCode;         // ���ɐ�R�[�h
      revDateRow       [resultLotVo.getCurrentRowIndex()] = new String();           // �t�]���t
      manuDateRow      [resultLotVo.getCurrentRowIndex()] = XxcmnUtility.stringValue(manufacturedDate); // �����N����
      koyuCodeRow      [resultLotVo.getCurrentRowIndex()] = koyuCode;                // �ŗL�L��
      shipToLocNameRow [resultLotVo.getCurrentRowIndex()] = shipToLocatName;         // ���Ɍ��ۊǑq�ɖ�     

      // *************************** //
      // *  ���b�g�t�]�h�~�`�F�b�N * //
      // *************************** //
      // * �ȉ��̏����ɓ��Ă͂܂�ꍇ�A�`�F�b�N���s���B
      // * �E���b�g�Ǘ��敪��1�F���b�g�Ǘ��i
      // * �E���b�g�t�]�`�F�b�N�s�v�t���O��Null
      // * �E���i���ʋ敪��1:���i
      // * �E�X�e�[�^�X��02:�˗��ρ@03:������  04:�o�ɕ񍐗L�̂��Âꂩ
      if (XxinvConstants.LOT_CTL_Y.equals(lotCtl)
        && XxcmnUtility.isBlankOrNull(lotRevNotExe)
          && XxinvConstants.PRODUCT_FLAG_PROD.equals(productFlg)
          &&(XxinvConstants.STATUS_02.equals(status)
            || XxinvConstants.STATUS_03.equals(status)
            || XxinvConstants.STATUS_04.equals(status)))
      {
        // ���b�g�t�]�h�~�`�F�b�N
        HashMap data = XxinvUtility.doCheckLotReversal(
                         getOADBTransaction(),
                         itemCode,
                         lotNo,
                         shipToLocatId,
                         actualArrivalDate);

        Number result  = (Number)data.get("result");  // ��������
        Date   revDate = (Date)  data.get("revDate"); // �t�]���t

        // API���s���ʂ�1:�G���[�̏ꍇ
        if (XxinvConstants.RETURN_NOT_EXE.equals(result))
        {
          // ���b�g�t�]�h�~�G���[�t���O��Y�ɐݒ�
          lotRevErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          revDateRow[resultLotVo.getCurrentRowIndex()]      = XxcmnUtility.stringValue(revDate); // �t�]���t
        }
      }
        
      // ******************** //
      // *  �����\���擾  * //
      // ******************** //       
      // �����\���Z�oAPI���s
      Number canEncQty = XxinvUtility.getCanEncQty(
                           getOADBTransaction(),
                           shipToLocatId,
                           itemId,
                           lotId,
                           lotCtl);
      double canEncQtyD      = XxcmnUtility.doubleValue(canEncQty);       // �����\��
      double actualQtyInputD = doConversion(convertQuantity, numOfCases); // ���ѐ���(���͒l)

      // �X�e�[�^�X��05�F���ɕ񍐗L OR 06�F���o�ɕ񍐗L�̏ꍇ
      if (XxinvConstants.STATUS_05.equals(status) || XxinvConstants.STATUS_06.equals(status))
      {
        double resultActualQtyD = 0;
        // ���у��b�g������ꍇ
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // �ړ�����ID
              documentTypeCode,              // �����^�C�v
              recordTypeCode,                // ���R�[�h�^�C�v
              lotId))                        // ���b�gID
        {
          // ���ѐ���(���у��b�g)�擾
          resultActualQtyD = XxcmnUtility.doubleValue(
                               XxinvUtility.getActualQuantity(
                                 getOADBTransaction(),
                                 movLineId,             // �ړ�����ID
                                 documentTypeCode,      // �����^�C�v
                                 recordTypeCode,        // ���R�[�h�^�C�v
                                 lotId));               // ���b�gID
        }

        // ���ѐ���(���у��b�g) > ���ѐ���(���͒l) (���ѐ��ʂ����炵�ēo�^����ꍇ)�̂݃`�F�b�N�s��
        if (resultActualQtyD > actualQtyInputD)
        {
          // ********************************* //
          // *   �����\�݌ɐ��s���`�F�b�N  * //
          // ********************************* //
          // �����\�� - (���ѐ���(���у��b�g) - ���ѐ���(���͒l)) ��0��菬�����Ȃ�ꍇ�A�x��
          if ((canEncQtyD - (resultActualQtyD - actualQtyInputD)) < 0)
          {
            // �����\�݌ɐ��s���`�F�b�N�G���[�t���O��Y�ɐݒ�
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }
        }
          
      // �X�e�[�^�X��02�F�˗��� OR 03�F������ OR 04�F�o�ɕ񍐗L�̏ꍇ
      } else if (XxinvConstants.STATUS_02.equals(status)
          || XxinvConstants.STATUS_03.equals(status) 
          || XxinvConstants.STATUS_04.equals(status))
      { 

        // ********************************* //
        // *   �����\�݌ɐ��s���`�F�b�N  * //
        // ********************************* //
        // �w�����b�g������ꍇ�̂݃`�F�b�N���s��
        if (XxinvUtility.checkMovLotDtl(
              getOADBTransaction(),
              movLineId,                     // �ړ�����ID
              documentTypeCode,              // �����^�C�v
              XxinvConstants.RECORD_TYPE_10, // ���R�[�h�^�C�v 10:�w��
              lotId))                        // ���b�gID
        { 
          // ���ѐ���(�w�����b�g)�擾
          double indicateActualQtyD = XxcmnUtility.doubleValue(
                                         XxinvUtility.getActualQuantity(
                                           getOADBTransaction(),
                                           movLineId,                     // �ړ�����ID
                                           documentTypeCode,              // �����^�C�v
                                           XxinvConstants.RECORD_TYPE_10, // ���R�[�h�^�C�v 10:�w��
                                           lotId));                       // ���b�gID

          // * �ȉ��̏������ׂĂɓ��Ă͂܂�ꍇ
          // * �E���ɗ\��� < ���Ɏ��ѓ� (��|���œ��ɂ����ꍇ)
          // * �E�����\�� - ���ѐ���(���͒l) ��0��菬�����Ȃ�ꍇ 
          if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, scheduleArrivalDate)
            && ((canEncQtyD - actualQtyInputD) < 0))
          {
            // �����\�݌ɐ��s���`�F�b�N�G���[�t���O��Y�ɐݒ�
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;

          // * �ȉ��̏������ׂĂɓ��Ă͂܂�ꍇ
          // * �E���ѐ���(�w�����b�g) > ���ѐ���(���͒l) (�w�����b�g��菭�Ȃ��o�^����ꍇ)
          // * �E�����\�� - (���ѐ���(�w�����b�g) - ���ѐ���(���͒l))��0��菬�����Ȃ�ꍇ
          } else if ((indicateActualQtyD > actualQtyInputD) 
              && ((canEncQtyD - (indicateActualQtyD - actualQtyInputD)) < 0))
          {
            // �����\�݌ɐ��s���`�F�b�N�G���[�t���O��Y�ɐݒ�
            shortageErrFlgRow[resultLotVo.getCurrentRowIndex()] = XxcmnConstants.STRING_Y;
          }           
        }
      }

      // ���̃��R�[�h��
      resultLotVo.next();
    } 
    msg.put("lotRevErrFlg",     (String[])lotRevErrFlgRow);  // ���b�g�t�]�h�~�`�F�b�N�G���[�t���O
    msg.put("shortageErrFlg",   (String[])shortageErrFlgRow);// �����\�݌ɐ��s���`�F�b�N�G���[�t���O
    msg.put("itemName",         (String[])itemNameRow);      // �i�ږ�
    msg.put("lotNo",            (String[])lotNoRow);         // ���b�gNo
    msg.put("shipToLocCode",    (String[])shipToLocCodeRow); // ���ɐ�R�[�h
    msg.put("revDate",          (String[])revDateRow);       // �t�]���t
    msg.put("manufacturedDate", (String[])manuDateRow);      // �����N����
    msg.put("koyuCode",         (String[])koyuCodeRow);      // �ŗL�L��
    msg.put("shipToLocName",    (String[])shipToLocNameRow); // ���Ɍ��ۊǑq�ɖ�

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
   * �o�Ƀ��b�g��ʂ̓o�^�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ****************************************************************************/
  public void entryDataShipped() throws OAException
  {    
    // ***************************** //
    // *  ���b�N�擾�E�r���`�F�b�N * //
    // ***************************** //
    getLockAndChkExclusive();

    // ����VO�擾
    OAViewObject lineVo     = getXxinvLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // ���R�[�h�^�C�v
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");       // �ړ�����ID
    Number movHeaderId      = (Number)lineRow.getAttribute("MovHdrId");        // �ړ��w�b�_ID
    String productFlg       = (String)lineRow.getAttribute("ProductFlg");      // ���i���ʋ敪
    String movNum           = (String)lineRow.getAttribute("MovNum");          // �ړ��ԍ�
    String compActualFlg    = (String)lineRow.getAttribute("CompActualFlg");   // ���ьv��σt���O
    String status           = (String)lineRow.getAttribute("Status");          // �X�e�[�^�X
    String actualQtySum = null;

    // �I�����b�Z�[�W�i�[
    ArrayList infoMsg = new ArrayList(100);

    // ******************************** //
    // *  �ړ����b�g�ڍ׎��ѓo�^����  * //
    // ******************************** //
    insertResultLot();

// 2008-07-14 Y.Yamamoto Del START
    // *********************************** // 
    // *  �d�ʗe�Ϗ������X�V�֐����s   * //
    // *********************************** //
//    Number ret = XxinvUtility.doUpdateLineItems(getOADBTransaction(), XxcmnConstants.BIZ_TYPE_MOV, movNum);

    // �d�ʗe�Ϗ����X�V�֐��̖߂�l��1�F�G���[�̏ꍇ
//    if (XxinvConstants.RETURN_NOT_EXE.equals(ret))
//    {
      // ���[���o�b�N
//      XxinvUtility.rollBack(getOADBTransaction());
      // �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W�o��
//      throw new OAException(
//          XxcmnConstants.APPL_XXINV, 
//          XxinvConstants.XXINV10127);
//    }
// 2008-07-14 Y.yamamoto Del END
   
    // ********************** // 
    // *  ���ѐ��ʍ��v�擾  * //
    // ********************** //
    actualQtySum = XxinvUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     movLineId,
                     documentTypeCode,
                     recordTypeCode);

    // ********************************** // 
    // *  �ړ����׏o�Ɏ��ѐ��ʍX�V����  * //
    // ********************************** //
    XxinvUtility.updateShippedQuantity(
      getOADBTransaction(),
      movLineId,
      actualQtySum);

    // �S�ړ����׏o�Ɏ��ѐ��ʓo�^�σ`�F�b�N (true:�o�^��  false:���o�^����)
    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
    // �S�ړ����ד��Ɏ��ѐ��ʓo�^�σ`�F�b�N (true:�o�^��  false:���o�^����)
    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");

    // �X�e�[�^�X��02�F�˗��� OR 03�F������ OR 05�F���ɕ񍐗L�̏ꍇ
    if (XxinvConstants.STATUS_02.equals(status)
        || XxinvConstants.STATUS_03.equals(status) 
        || XxinvConstants.STATUS_05.equals(status))
    { 
      // ���ѐ��ʂ��o�^�ς̏ꍇ�A�X�e�[�^�X�̍X�V�����s
      if (shippedResultFlag)
      {
        // ********************************** // 
        // *  �ړ��w�b�_�X�e�[�^�X�X�V����  * //
        // ********************************** //
        updateStatus(movHeaderId, recordTypeCode);
      }

    // �X�e�[�^�X��04�F�o�ɕ񍐗L OR 06�F���o�ɕ񍐗L�̏ꍇ
    } else if (XxinvConstants.STATUS_04.equals(status) || XxinvConstants.STATUS_06.equals(status))
    {
      // ���ьv��σt���O��ON�̏ꍇ
      if (XxcmnConstants.STRING_Y.equals(compActualFlg))
      {
        // ************************************** // 
        // *  �ړ��w�b�_���ђ����t���O�X�V����  * //
        // ************************************** // 
        XxinvUtility.updateCorrectActualFlg(getOADBTransaction(), movHeaderId);
      }
    }

// 2008-07-14 Y.Yamamoto Add START
    // *********************************** // 
    // *  �d�ʗe�Ϗ������X�V�֐����s   * //
    // *********************************** //
    Number ret = XxinvUtility.doUpdateLineItems(getOADBTransaction(), XxcmnConstants.BIZ_TYPE_MOV, movNum);

    // �d�ʗe�Ϗ����X�V�֐��̖߂�l��1�F�G���[�̏ꍇ
    if (XxinvConstants.RETURN_NOT_EXE.equals(ret))
    {
      // ���[���o�b�N
      XxinvUtility.rollBack(getOADBTransaction());
      // �d�ʗe�Ϗ������X�V�֐��G���[���b�Z�[�W�o��
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10127);
    }
// 2008-07-14 Y.yamamoto Add END

    // ***************** //
    // *  �R�~�b�g     * //
    // ***************** //
    XxinvUtility.commit(getOADBTransaction());


    // �ړ����ׂ̏o�Ɏ��ѐ��ʁE���Ɏ��ѐ��ʂ����ɂ��ׂēo�^�ς̏ꍇ
    if (shippedResultFlag && shipToResultFlag)
    {    
      // ******************************************* // 
      // *  �ړ����o�Ɏ��ѓo�^����(�R���J�����g)   * //
      // ******************************************* //
      HashMap param = new HashMap();
      param.put("MovNum", movNum); // �ړ��ԍ�
      HashMap retHashMap = XxinvUtility.doMovShipActualMake(getOADBTransaction(), param);

      // �R���J�����g����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals((String)retHashMap.get("retFlag")))
      {
        // �R���J�����g����I�����b�Z�[�W�擾
        MessageToken[] tokens = new MessageToken[2];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
        tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID,      retHashMap.get("requestId").toString());
        infoMsg.add(
          new OAException(
                 XxcmnConstants.APPL_XXINV,
                 XxinvConstants.XXINV10006,
                 tokens,
                 OAException.INFORMATION,
                 null));
      }
    }

    // ******************** // 
    // *  �ĕ\��          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("movLineId",      movLineId.toString()); // �ړ�����ID
    params.put("productFlg",     productFlg);           // ���i���ʋ敪
    params.put("recordTypeCode", recordTypeCode);       // ���R�[�h�^�C�v 
    initialize(params);

    // �o�^�������b�Z�[�W�擾
    infoMsg.add( new OAException(XxcmnConstants.APPL_XXINV,
                                  XxinvConstants.XXINV10161, 
                                  null, 
                                  OAException.INFORMATION, 
                                  null));

    // PVO�擾
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // ���b�g�t�]�`�F�b�N�s�v�t���O�ݒ�
    pvoRow.setAttribute("lotRevNotExe", "1");

    // **************************** // 
    // *  �o�^�������b�Z�[�W�o��  * //
    // **************************** //
    if (infoMsg.size() > 0)
    {
      OAException.raiseBundledOAException(infoMsg);
    }   
  }

 /*****************************************************************************
   * ���Ƀ��b�g��ʂ̓o�^�������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ****************************************************************************/
  public void entryDataShipTo() throws OAException
  {    
    // ***************************** //
    // *  ���b�N�擾�E�r���`�F�b�N * //
    // ***************************** //
    getLockAndChkExclusive();

    // ����VO�擾
    OAViewObject lineVo     = getXxinvLineVO1();
    OARow        lineRow    = (OARow)lineVo.first();
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode");// �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");  // ���R�[�h�^�C�v
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");       // �ړ�����ID
    Number movHeaderId      = (Number)lineRow.getAttribute("MovHdrId");        // �ړ��w�b�_ID
    String productFlg       = (String)lineRow.getAttribute("ProductFlg");      // ���i���ʋ敪
    String movNum           = (String)lineRow.getAttribute("MovNum");          // �ړ��ԍ�
    String compActualFlg    = (String)lineRow.getAttribute("CompActualFlg");   // ���ьv��σt���O
    String status           = (String)lineRow.getAttribute("Status");          // �X�e�[�^�X
    String actualQtySum = null;

    // �I�����b�Z�[�W�i�[
    ArrayList infoMsg = new ArrayList(100);

    // ******************************** //
    // *  �ړ����b�g�ڍ׎��ѓo�^����  * //
    // ******************************** //
    insertResultLot();

    // ********************** // 
    // *  ���ѐ��ʍ��v�擾  * //
    // ********************** //
    actualQtySum = XxinvUtility.getActualQuantitySum(
                     getOADBTransaction(),
                     movLineId,
                     documentTypeCode,
                     recordTypeCode);

    // ********************************** // 
    // *  �ړ����ד��Ɏ��ѐ��ʍX�V����  * //
    // ********************************** //
    XxinvUtility.updateShipToQuantity(
      getOADBTransaction(),
      movLineId,
      actualQtySum);

    // �S�ړ����׏o�Ɏ��ѐ��ʓo�^�σ`�F�b�N (true:�o�^��  false:���o�^����)
    boolean shippedResultFlag = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1");
    // �S�ړ����ד��Ɏ��ѐ��ʓo�^�σ`�F�b�N (true:�o�^��  false:���o�^����)
    boolean shipToResultFlag  = XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2");

    // �X�e�[�^�X��02�F�˗��� OR 03�F������ OR 04�F�o�ɕ񍐗L�̏ꍇ
    if (XxinvConstants.STATUS_02.equals(status)
        || XxinvConstants.STATUS_03.equals(status) 
        || XxinvConstants.STATUS_04.equals(status))
    { 
      // ���ѐ��ʂ��o�^�ς̏ꍇ�A�X�e�[�^�X�̍X�V�����s
      if (shipToResultFlag)
      {
        // ********************************** // 
        // *  �ړ��w�b�_�X�e�[�^�X�X�V����  * //
        // ********************************** //
        updateStatus(movHeaderId, recordTypeCode);
      }

    // �X�e�[�^�X��05�F���ɕ񍐗L OR 06�F���o�ɕ񍐗L�̏ꍇ
    } else if (XxinvConstants.STATUS_05.equals(status) || XxinvConstants.STATUS_06.equals(status))
    {
      // ���ьv��σt���O��ON�̏ꍇ
      if (XxcmnConstants.STRING_Y.equals(compActualFlg))
      {
        // ************************************** // 
        // *  �ړ��w�b�_���ђ����t���O�X�V����  * //
        // ************************************** // 
        XxinvUtility.updateCorrectActualFlg(getOADBTransaction(), movHeaderId);
      }
    }
    
    // ***************** //
    // *  �R�~�b�g     * //
    // ***************** //
    XxinvUtility.commit(getOADBTransaction());

    // �ړ����ׂ̏o�Ɏ��ѐ��ʁE���Ɏ��ѐ��ʂ����ɂ��ׂēo�^�ς̏ꍇ
    if (shippedResultFlag && shipToResultFlag)
    {    
      // ******************************************* // 
      // *  �ړ����o�Ɏ��ѓo�^����(�R���J�����g)   * //
      // ******************************************* //
      HashMap param = new HashMap();
      param.put("MovNum", movNum); // �ړ��ԍ�
      HashMap ret = XxinvUtility.doMovShipActualMake(getOADBTransaction(), param);

      // �R���J�����g����I���̏ꍇ
      if (XxcmnConstants.RETURN_SUCCESS.equals((String)ret.get("retFlag")))
      {
        // �R���J�����g����I�����b�Z�[�W�擾
        MessageToken[] tokens = new MessageToken[2];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_PROGRAM, XxinvConstants.TOKEN_NAME_MOV_ACTUAL_MAKE);
        tokens[1] = new MessageToken(XxinvConstants.TOKEN_ID,      ret.get("requestId").toString());
        infoMsg.add(
          new OAException(
                 XxcmnConstants.APPL_XXINV,
                 XxinvConstants.XXINV10006,
                 tokens,
                 OAException.INFORMATION,
                 null));
      }
    }

    // ******************** // 
    // *  �ĕ\��          * //
    // ******************** //    
    HashMap params = new HashMap();
    params.put("movLineId",      movLineId.toString()); // �ړ�����ID
    params.put("productFlg",     productFlg);           // ���i���ʋ敪
    params.put("recordTypeCode", recordTypeCode);       // ���R�[�h�^�C�v 
    initialize(params);

    // �o�^�������b�Z�[�W�擾
    infoMsg.add( new OAException(XxcmnConstants.APPL_XXINV,
                                  XxinvConstants.XXINV10161, 
                                  null, 
                                  OAException.INFORMATION, 
                                  null));

    // PVO�擾
    OAViewObject pvo = getXxInvMovementShippedLotPVO1();
    // PVO1�s�ڂ��擾
    OARow pvoRow = (OARow)pvo.first();
    // ���b�g�t�]�`�F�b�N�s�v�t���O�ݒ�
    pvoRow.setAttribute("lotRevNotExe", "1");
    // **************************** // 
    // *  �o�^�������b�Z�[�W�o��  * //
    // **************************** //
    if (infoMsg.size() > 0)
    {
      OAException.raiseBundledOAException(infoMsg);
    }   
  }

 /*****************************************************************************
  * ���b�N���擾���A�r���`�F�b�N���s�����\�b�h�ł��B
  * @throws OAException - OA��O
  ****************************************************************************/
  public void getLockAndChkExclusive() throws OAException
  {
    // ����VO�擾
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();

    Number movHdrId         = (Number)lineRow.getAttribute("MovHdrId");         // �ړ��w�b�_ID
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");        // �ړ�����ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // ���R�[�h�^�C�v
    String headerUpdateDate = (String)lineRow.getAttribute("HeaderUpdateDate"); // �w�b�_�X�V����
    String lineUpdateDate   = (String)lineRow.getAttribute("LineUpdateDate");   // ���׍X�V����

    // ************************ //
    // *   �ړ��w�b�_���b�N   * //
    // ************************ //
    // ���b�N�擾�Ɏ��s�����ꍇ
    if (!XxinvUtility.getMovReqInstrHdrLock(getOADBTransaction(), movHdrId))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }

    // ********************** //
    // *   �ړ����׃��b�N   * //
    // ********************** //
    // ���b�N�擾�Ɏ��s�����ꍇ
    if (!XxinvUtility.getMovReqInstrLineLock(getOADBTransaction(), movLineId))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }

    // *************************** //
    // *  �ړ����b�g�ڍ׃��b�N   * //
    // *************************** //
    // ���b�N�G���[�̏ꍇ
    if (!XxinvUtility.getMovLotDetailsLock(
          getOADBTransaction(),
          movLineId,
          documentTypeCode,
          recordTypeCode))
    {
      // ���b�N�G���[���b�Z�[�W�o��
      throw new OAException(
          XxcmnConstants.APPL_XXINV, 
          XxinvConstants.XXINV10159);
    }
    
    // ******************************** //
    // *   �ړ��w�b�_�r���`�F�b�N     * //
    // ******************************** //
    // �r���G���[�̏ꍇ
    if (!XxinvUtility.chkExclusiveMovReqInstrHdr(getOADBTransaction(), movHdrId, headerUpdateDate))
    {
// 2008-07-10 H.Itou Mod START
      // �������g�̃R���J�����g�N���ɂ��X�V���ꂽ�ꍇ�͔r���G���[�Ƃ��Ȃ�
      if (!XxinvUtility.isMovHdrUpdForOwnConc(
             getOADBTransaction(),
             movHdrId,
             XxinvConstants.CONC_NAME_XXINV570001C))
      {
        // ���[���o�b�N
        XxinvUtility.rollBack(getOADBTransaction());
        
        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10147);
      }
// 2008-07-10 H.Itou Mod END
    }

    // ******************************** //
    // *   �ړ����הr���`�F�b�N       * //
    // ******************************** //
    // �r���G���[�̏ꍇ
    if (!XxinvUtility.chkExclusiveMovReqInstrLine(getOADBTransaction(), movLineId, lineUpdateDate))
    {
// 2008-07-10 H.Itou Mod START
      // �������g�̃R���J�����g�N���ɂ��X�V���ꂽ�ꍇ�͔r���G���[�Ƃ��Ȃ�
      if (!XxinvUtility.isMovLineUpdForOwnConc(
             getOADBTransaction(),
             movLineId,
             XxinvConstants.CONC_NAME_XXINV570001C))
      {
        // ���[���o�b�N
        XxinvUtility.rollBack(getOADBTransaction());

        // �r���G���[���b�Z�[�W�o��
        throw new OAException(
            XxcmnConstants.APPL_XXCMN, 
            XxcmnConstants.XXCMN10147);
      }
// 2008-07-10 H.Itou Mod END
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
    OAViewObject lineVo  = getXxinvLineVO1();
    OARow        lineRow = (OARow)lineVo.first();
    Number movLineId        = (Number)lineRow.getAttribute("MovLineId");         // �ړ�����ID
    String documentTypeCode = (String)lineRow.getAttribute("DocumentTypeCode"); // �����^�C�v
    String recordTypeCode   = (String)lineRow.getAttribute("RecordTypeCode");   // ���R�[�h�^�C�v
      
    // ���у��b�gVO�擾
    OAViewObject resultLotVo = getXxinvResultLotVO1();
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
      if (XxinvUtility.checkMovLotDtl(
            getOADBTransaction(),
            movLineId,           // �ړ�����ID
            documentTypeCode,      // �����^�C�v
            recordTypeCode,        // ���R�[�h�^�C�v
            lotId))                // ���b�gID
      {    
        // ************************************ // 
        // *  �ړ����b�g�ڍ׎��ѐ��ʍX�V����  * //
        // ************************************ //
        XxinvUtility.updateActualQuantity(getOADBTransaction(), data);
        
      // ���у��b�g���o�^�ςłȂ��ꍇ(���ѐV�K��)
      } else
      {       
        // **************************** // 
        // *  �ړ����b�g�ڍדo�^����  * //
        // **************************** //       
        XxinvUtility.insertMovLotDetails(getOADBTransaction(), data);          

      }
      // ���̃��R�[�h��
      resultLotVo.next();
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
    String convertQuantity = (String)resultLotRow.getAttribute("ConvertQuantity");
    Number numOfCases      = (Number)lineRow.getAttribute("NumOfCases");
    String recordTypeCode  = (String)lineRow.getAttribute("RecordTypeCode");
    
    HashMap ret = new HashMap();

    ret.put("movLineId",          lineRow.getAttribute("MovLineId"));             // �ړ�����ID
    ret.put("documentTypeCode",   lineRow.getAttribute("DocumentTypeCode"));      // �����^�C�v
    ret.put("recordTypeCode",     lineRow.getAttribute("RecordTypeCode"));        // ���R�[�h�^�C�v
    ret.put("itemId",             lineRow.getAttribute("ItemId"));                // �i��ID
    ret.put("itemCode",           lineRow.getAttribute("ItemCode"));              // �i�ڃR�[�h
    ret.put("lotId",              resultLotRow.getAttribute("LotId"));            // ���b�gID
    ret.put("lotNo",              resultLotRow.getAttribute("LotNo"));            // ���b�gNo
    ret.put("manufacturedDate",   resultLotRow.getAttribute("ManufacturedDate")); // �����N����
    ret.put("useByDate",          resultLotRow.getAttribute("UseByDate"));        // �ܖ�����
    ret.put("koyuCode",           resultLotRow.getAttribute("KoyuCode"));         // �ŗL�L��
    ret.put("actualQuantity",     Double.toString(doConversion(convertQuantity, numOfCases)));// ���ѐ���   
     // ���R�[�h�^�C�v��20�F�o�Ɏ��т̏ꍇ
    if (XxinvConstants.RECORD_TYPE_20.equals(recordTypeCode))
    {
      ret.put("actualDate",         lineRow.getAttribute("ActualShipDate"));      // ���ѓ� = �o�Ɏ��ѓ�

    //  ���R�[�h�^�C�v��30�F���Ɏ��т̏ꍇ
    } else
    {
      ret.put("actualDate",         lineRow.getAttribute("ActualArrivalDate"));   // ���ѓ� = ���Ɏ��ѓ�
    }

    return ret;
  }

  /***************************************************************************
   * �ړ��˗�/�w���w�b�_�X�e�[�^�X���X�V���郁�\�b�h�ł��B
   * @param  movHeaderId     - �ړ��w�b�_ID
   * @param  recordTypeCode  - ���R�[�h�^�C�v 20:�o�Ɏ��� 30:���Ɏ���
   * @throws OAException     - OA��O
   ***************************************************************************
   */
  public void updateStatus(
    Number movHeaderId, 
    String recordTypeCode)
  throws OAException
  {
    String status = null; // �X�e�[�^�X

    // �o�Ƀ��b�g���щ�ʂ̏ꍇ
    if (XxinvConstants.RECORD_TYPE_20.equals(recordTypeCode))
    {
      // �S�ړ����ד��Ɏ��ѐ��ʓo�^�σ`�F�b�N
      if (XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "2"))
      {
        // ���Ɏ��ѓo�^�ς̏ꍇ
        status = XxinvConstants.STATUS_06; // �X�e�[�^�X 06 ���o�ɕ񍐗L

      } else
      {
        // ���Ɏ��і��o�^����̏ꍇ
        status = XxinvConstants.STATUS_04; // �X�e�[�^�X 04 �o�ɕ񍐗L
      }      

    // ���Ƀ��b�g���щ�ʂ̏ꍇ
    } else
    {
      // �S�ړ����׏o�Ɏ��ѐ��ʓo�^�σ`�F�b�N
      if (XxinvUtility.isQuantityAllEntry(getOADBTransaction(), movHeaderId, "1"))
      {
        // �o�Ɏ��ѓo�^�ς̏ꍇ
        status = XxinvConstants.STATUS_06; // �X�e�[�^�X 06 ���o�ɕ񍐗L

      } else
      {
        // �o�Ɏ��і��o�^����̏ꍇ
        status = XxinvConstants.STATUS_05; // �X�e�[�^�X 05 ���ɕ񍐗L        
      }      
    }

    XxinvUtility.updateStatus(
      getOADBTransaction(),
      movHeaderId,
      status);
  }

  /**
   * 
   * Container's getter for XxinvLineVO1
   */
  public XxinvLineVOImpl getXxinvLineVO1()
  {
    return (XxinvLineVOImpl)findViewObject("XxinvLineVO1");
  }


  /**
   * 
   * Container's getter for XxinvResultLotVO1
   */
  public XxinvResultLotVOImpl getXxinvResultLotVO1()
  {
    return (XxinvResultLotVOImpl)findViewObject("XxinvResultLotVO1");
  }

  /**
   * 
   * Container's getter for XxInvMovementShippedLotPVO1
   */
  public XxInvMovementShippedLotPVOImpl getXxInvMovementShippedLotPVO1()
  {
    return (XxInvMovementShippedLotPVOImpl)findViewObject("XxInvMovementShippedLotPVO1");
  }

  /**
   * 
   * Container's getter for XxinvIndicateLotVO1
   */
  public XxinvIndicateLotVOImpl getXxinvIndicateLotVO1()
  {
    return (XxinvIndicateLotVOImpl)findViewObject("XxinvIndicateLotVO1");
  }


}