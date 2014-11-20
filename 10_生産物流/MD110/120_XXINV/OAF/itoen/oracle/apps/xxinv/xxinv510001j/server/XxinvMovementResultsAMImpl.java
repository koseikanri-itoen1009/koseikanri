/*============================================================================
* �t�@�C���� : XxinvMovementResultsAMImpl
* �T�v����   : ���o�Ɏ��їv��:�����A�v���P�[�V�������W���[��
* �o�[�W���� : 1.7
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-12 1.0  �勴�F�Y     �V�K�쐬
* 2008-06-11 1.2  �勴�F�Y     �s��w�E�����C��
* 2008-06-18 1.3  �勴�F�Y     �s��w�E�����C��
* 2008-06-26 1.4  �ɓ��ЂƂ�   ST#296�Ή�
* 2008-07-25 1.5  �R�{���v     �s��w�E�����C��
* 2008-08-20 1.6  �R�{���v     ST#249�Ή��A�����ύX#167�Ή�
* 2008-09-24 1.7  �ɓ��ЂƂ�   �����e�X�g �w�E59,156�Ή�
*============================================================================
*/
package itoen.oracle.apps.xxinv.xxinv510001j.server;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;
import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.common.MessageToken;
import oracle.jbo.Row;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxinv.util.XxinvUtility;

import itoen.oracle.apps.xxinv.util.XxinvConstants;

/***************************************************************************
 * ���o�Ɏ��їv��:�����A�v���P�[�V�������W���[���ł��B
 * @author  ORACLE �勴 �F�Y
 * @version 1.7
 ***************************************************************************
 */
public class XxinvMovementResultsAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxinvMovementResultsAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxinv.xxinv510001j.server", "XxinvMovementResultsAMLocal");
  }



  /**
   * 
   * Container's getter for XxinvMovResultsSearchVO1
   */
  public XxinvMovResultsSearchVOImpl getXxinvMovResultsSearchVO1()
  {
    return (XxinvMovResultsSearchVOImpl)findViewObject("XxinvMovResultsSearchVO1");
  }


  /***************************************************************************
   * ���o�Ɏ��їv���ʂ̏������������s�����\�b�h�ł��B
   * @param searchParams - �p�����[�^HashMap
   ***************************************************************************
   */
  public void initialize(
    HashMap searchParams
  )
  {
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();

    String actualFlag  = (String)searchParams.get("actualFlag");    // ���уf�[�^�敪
    String productFlag = (String)searchParams.get("productFlag");   // ���i���ʋ敪

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1�s�ڂ��擾
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      // �L�[�ɒl���Z�b�g
      resultsSearchRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchRow.setAttribute("RowKey", new Number(1));
      resultsSearchRow.setAttribute("ActualFlg", actualFlag);
      resultsSearchRow.setAttribute("ProductFlg", productFlag);
    }

    // ******************************* //
    // *     ���[�U�[���擾        * //
    // ******************************* //
    getUserData(actualFlag, "1");

  } // initialize

  /***************************************************************************
   * ���[�U�[�����擾���郁�\�b�h�ł��B
   * @param actualFlag ���уf�[�^�敪
   * @param exeType    �N�����(�v����:1�A�w�b�_���:2)
   ***************************************************************************
   */
  public void getUserData(
    String actualFlag,
    String exeType
  )
  {
    // ���[�U�[���擾
    HashMap paramsRet = XxinvUtility.getUserData(
                            getOADBTransaction()  // �g�����U�N�V����
                            );

    // ���͎��їv��VO�擾
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();

    // �]�ƈ��敪���Z�b�g
    resultsSearchRow.setAttribute("PeopleCode", paramsRet.get("retpeopleCode"));

    // �O�����[�U�̏ꍇ
    if (XxinvConstants.PEOPLE_CODE_O.equals(paramsRet.get("retpeopleCode")))
    {
      // �o�Ɏ��у��j���[����N��
      if (XxinvConstants.ACTUAL_FLAG_DELI.equals(actualFlag))
      {
        // �ۊǏꏊ���Z�b�g�ς݂̏ꍇ
        if ("2".equals(exeType))
        {
          // ���o�Ɏ��уw�b�_VO�擾
          OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
          // 1�s�ڂ��擾
          OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
          // �ۊǏꏊ���Z�b�g
          movementResultsHdRow.setAttribute("ShippedLocatId", paramsRet.get("locationId"));
          movementResultsHdRow.setAttribute("ShippedLocatCode", paramsRet.get("locationsCode"));
          movementResultsHdRow.setAttribute("Description1", paramsRet.get("locationsName"));
        } else if ("1".equals(exeType))
        {
          // �ۊǏꏊ���Z�b�g
          resultsSearchRow.setAttribute("ShipLcationCode", paramsRet.get("locationsCode"));
          resultsSearchRow.setAttribute("ShipLocationName", paramsRet.get("locationsName"));
          resultsSearchRow.setAttribute("ShipLocationId", paramsRet.get("locationId"));
        }

      // ���Ɏ��у��j���[����N��
      } else if (XxinvConstants.ACTUAL_FLAG_SCOC.equals(actualFlag))
      {
        // �ۊǏꏊ���Z�b�g�ς݂̏ꍇ
        if ("2".equals(exeType))
        {
          // ���o�Ɏ��уw�b�_VO�擾
          OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
          // 1�s�ڂ��擾
          OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
          // �ۊǏꏊ���Z�b�g
          movementResultsHdRow.setAttribute("ShipToLocatId", paramsRet.get("locationId"));
          movementResultsHdRow.setAttribute("ShipToLocatCode", paramsRet.get("locationsCode"));
          movementResultsHdRow.setAttribute("Description2", paramsRet.get("locationsName"));
        } else if ("1".equals(exeType))
        {
          // �ۊǏꏊ���Z�b�g
          resultsSearchRow.setAttribute("ArrivalLocationCode", paramsRet.get("locationsCode"));
          resultsSearchRow.setAttribute("ArrivalLocationName", paramsRet.get("locationsName"));
          resultsSearchRow.setAttribute("ArrivalLocationId", paramsRet.get("locationId"));
        }
      }
    }

  } // getUserData

  /***************************************************************************
   * ���o�Ɏ��їv���ʂ̌����������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  )
  {
    // �ړ����я��VO�擾
    XxinvMovementResultsVOImpl xxinvMovementResultsVo = getXxinvMovementResultsVO1();
    // ����
    String shippedLocatId      = (String)searchParams.get("shippedLocatId");

    xxinvMovementResultsVo.initQuery(searchParams); // �����p�����[�^�pHashMap

    // 1�s�ڂ��擾
    OARow row = (OARow)xxinvMovementResultsVo.first();
    
  } // doSearch

  /***************************************************************************
   * ���o�Ɏ��їv���ʂ̏o�ɓ�From�̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyShipDate()
  {
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovResultsSearchVO1();
    OARow row          = (OARow)vo.first();
    Date  shipDateFrom = (Date)row.getAttribute("ShipDateFrom");
    Date  shipDateTo   = (Date)row.getAttribute("ShipDateTo");

    // �o�ɓ�To��Null�̏ꍇ�A�o�ɓ�From���R�s�[
    if (XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      row.setAttribute("ShipDateTo", shipDateFrom);
    }
  } // copyShipDate

  /****************************************************************************
   * ���o�Ɏ��їv���ʂ̒���From�̃R�s�[�������s�����\�b�h�ł��B
   ****************************************************************************
   */
  public void copyArrivalDate()
  {
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovResultsSearchVO1();
    OARow row             = (OARow)vo.first();
    Date  arrivalDateFrom = (Date)row.getAttribute("ArrivalDateFrom");
    Date  arrivalDateTo   = (Date)row.getAttribute("ArrivalDateTo");

    // ����To��Null�̏ꍇ�A����From���R�s�[
    if (XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      row.setAttribute("ArrivalDateTo", arrivalDateFrom);
    }
  } // copyArrivalDate

  /***************************************************************************
   * ���o�Ɏ��їv���ʂ̌������ږ��w��`�F�b�N���s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   ***************************************************************************
   */
  public void doItemCheck(
    HashMap searchParams
  )
  {
    // ���͍��ڐ�
    int itemCount = 0;
    
    // ���������擾
    String movNum              = (String)searchParams.get("movNum");              // �ړ��ԍ�
    String movType             = (String)searchParams.get("movType");             // �ړ��^�C�v
    String status              = (String)searchParams.get("status");              // �X�e�[�^�X
    String shippedLocatId      = (String)searchParams.get("shippedLocatId");      // �o�Ɍ�
    String shipToLocatId       = (String)searchParams.get("shipToLocatId");       // ���ɐ�
    String shipDateFrom        = (String)searchParams.get("shipDateFrom");        // �o�ɓ�(�J�n)
    String shipDateTo          = (String)searchParams.get("shipDateTo");          // �o�ɓ�(�I��)
    String arrivalDateFrom     = (String)searchParams.get("arrivalDateFrom");     // ����(�J�n)
    String arrivalDateTo       = (String)searchParams.get("arrivalDateTo");       // ����(�I��)
    String instructionPostCode = (String)searchParams.get("instructionPostCode"); // �ړ��w������
    String deliveryNo          = (String)searchParams.get("deliveryNo");          // �z��No

    // �ړ��ԍ�
    if (!XxcmnUtility.isBlankOrNull(movNum))
    {
      itemCount = itemCount + 1;
    }
    // �ړ��^�C�v
    if (!XxcmnUtility.isBlankOrNull(movType))
    {
      itemCount = itemCount + 1;
    }
    // �X�e�[�^�X
    if (!XxcmnUtility.isBlankOrNull(status))
    {
      itemCount = itemCount + 1;
    }
    // �o�Ɍ�
    if (!XxcmnUtility.isBlankOrNull(shippedLocatId))
    {
      itemCount = itemCount + 1;
    }
    // ���ɐ�
    if (!XxcmnUtility.isBlankOrNull(shipToLocatId))
    {
      itemCount = itemCount + 1;
    }
    // �o�ɓ�(�J�n)
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      itemCount = itemCount + 1;
    }
    // �o�ɓ�(�I��)
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      itemCount = itemCount + 1;
    }
    // ����(�J�n)
    if (!XxcmnUtility.isBlankOrNull(arrivalDateFrom))
    {
      itemCount = itemCount + 1;
    }
    // ����(�I��)
    if (!XxcmnUtility.isBlankOrNull(arrivalDateTo))
    {
      itemCount = itemCount + 1;
    }
    // �ړ��w������
    if (!XxcmnUtility.isBlankOrNull(instructionPostCode))
    {
      itemCount = itemCount + 1;
    }
    // �z��No
    if (!XxcmnUtility.isBlankOrNull(deliveryNo))
    {
      itemCount = itemCount + 1;
    }
    // �����������S�Ė����͂̏ꍇ
    if (itemCount == 0)
    {
      // �G���[���b�Z�[�W�o��
      throw new OAException(
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10043);
    }
  } // doItemCheck

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̓E�v�{�^���̖����ؑ֐�����s�����\�b�h�ł��B
   * @param flag - 0:�L��
   *              - 1:����
   ***************************************************************************
   */
  public void disabledChanged(
    String flag
  )
  {
    // ���o�Ɏ��уw�b�_:�o�^:�o�^PVO�擾
    OAViewObject movementResultsHdPvo = getXxinvMovementResultsHdPVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)movementResultsHdPvo.first();

    // �t���O��0:�L���̏ꍇ
    if ("0".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.FALSE); // �K�p�{�^��������

    // �t���O��1:�����̏ꍇ
    } else if ("1".equals(flag))
    {
      readOnlyRow.setAttribute("GoDisabled",  Boolean.TRUE); // �K�p�{�^�������s��
    }
  } // disabledChanged

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̓��͐�����s�����\�b�h�ł��B
   * @param peocessFlag �����t���O
   ***************************************************************************
   */
  public void readOnlyChanged(String peocessFlag)
  {
    // ���o�Ɏ��уw�b�_:�o�^PVO�擾
    OAViewObject resultsHdrPVO = getXxinvMovementResultsHdPVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)resultsHdrPVO.first();

    // �����t���O:1(�o�^)�̏ꍇ
    if ("1".equals(peocessFlag))
    {
      // ���o�Ɏ��уw�b�_:����VO�擾
      OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      // 1�s�ڂ��擾
      OARow searchVoRow = (OARow)resultsSearchVo.first();
      
    // mod start ver1.5
      // ���i���ʋ敪:2(���i�ȊO)�̏ꍇ
//      if ("2".equals(searchVoRow.getAttribute("ProductFlg")))
//      {
        // �w�b�_.�^���Ǝ҂�ǎ��p�ɕύX
//        readOnlyRow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE);
//      }
    // mod end ver1.5
      // �w�b�_.�C���t���O��ǎ��p�ɕύX
      readOnlyRow.setAttribute("NewModifyFlgReadOnly", Boolean.TRUE);
      // �w�b�_.�ړ��^�C�v��ǎ��p�ɕύX
      readOnlyRow.setAttribute("MovTypeReadOnly", Boolean.TRUE);

    // �����t���O:2(�X�V)�̏ꍇ
    } else if ("2".equals(peocessFlag))
    {
      // ���o�Ɏ��уw�b�_:�o�^VO�擾
      OAViewObject resultsHdrVO = getXxinvMovementResultsHdVO1();
      // 1�s�ڂ��擾
      OARow row = (OARow)resultsHdrVO.first();
      String deliveryNo = (String)row.getAttribute("DeliveryNo");
      
      // �w�b�_.�ړ��w��������ǎ��p�ɕύX
      readOnlyRow.setAttribute("InstructionPostReadOnly", Boolean.TRUE);
      // �w�b�_.�ړ��^�C�v��ǎ��p�ɕύX
      readOnlyRow.setAttribute("MovTypeReadOnly", Boolean.TRUE);
      // �w�b�_.�C���t���O��ǎ��p�ɕύX
      readOnlyRow.setAttribute("NewModifyFlgReadOnly", Boolean.TRUE);
      // �w�b�_.�o�Ɍ���ǎ��p�ɕύX
      readOnlyRow.setAttribute("ShippedLocatReadOnly", Boolean.TRUE);
      // �w�b�_.���ɐ��ǎ��p�ɕύX
      readOnlyRow.setAttribute("ShipToLocatReadOnly", Boolean.TRUE);
      // �z��No���t�^����Ă����ꍇ
      if (!XxcmnUtility.isBlankOrNull(deliveryNo))
      {
        // �w�b�_.�o�ɓ�(����)��ǎ��p�ɕύX
        readOnlyRow.setAttribute("ActualShipDateReadOnly", Boolean.TRUE);
        // �w�b�_.����(����)��ǎ��p�ɕύX
        readOnlyRow.setAttribute("ActualArrivalDateReadOnly", Boolean.TRUE);
      } else
      {
        // �w�b�_.�o�ɓ�(����)��ǎ��p�ɕύX
        readOnlyRow.setAttribute("ActualShipDateReadOnly", Boolean.FALSE);
        // �w�b�_.����(����)��ǎ��p�ɕύX
        readOnlyRow.setAttribute("ActualArrivalDateReadOnly", Boolean.FALSE);
      }
      // �w�b�_.�^���敪��ǎ��p�ɕύX
      readOnlyRow.setAttribute("FreightChargeClassReadOnly", Boolean.TRUE);
      // �w�b�_.�^���Ǝ҂�ǎ��p�ɕύX
      readOnlyRow.setAttribute("FreightCarrierReadOnly", Boolean.TRUE);
      // �w�b�_.���Ԏw��From��ǎ��p�ɕύX
      readOnlyRow.setAttribute("ArrivalTimeFromReadOnly", Boolean.TRUE);
      // �w�b�_.���Ԏw��To��ǎ��p�ɕύX
      readOnlyRow.setAttribute("ArrivalTimeToReadOnly", Boolean.TRUE);
      // �w�b�_.�p���b�g���������ǎ��p�ɕύX
      readOnlyRow.setAttribute("CollectedPalletReadOnly", Boolean.TRUE);
      // �w�b�_.�_��O�^���敪��ǎ��p�ɕύX
      readOnlyRow.setAttribute("NoContFreightClassReadOnly", Boolean.TRUE);
      // �w�b�_.�d�ʗe�ϋ敪��ǎ��p�ɕύX
      readOnlyRow.setAttribute("WeightCapacityClassReadOnly", Boolean.TRUE);
      // �w�b�_.�E�v��ǎ��p�ɕύX
      readOnlyRow.setAttribute("DescriptionReadOnly", Boolean.TRUE);
    }
  } // readOnlyChanged

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̏������������s�����\�b�h�ł��B
   * @param searchParams - �p�����[�^HashMap
   ***************************************************************************
   */
  public void initializeHdr(
    HashMap searchParams
  )
  {
    // �p�����[�^�擾
    String peopleCode  = (String)searchParams.get(XxinvConstants.URL_PARAM_PEOPLE_CODE);
    String actualFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_ACTUAL_FLAG);
    String productFlag = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);
    String itemClass   = (String)searchParams.get(XxinvConstants.URL_PARAM_ITEM_CLASS);
    String updateFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_UPDATE_FLAG);

    // ************************************* //
    // *    ���o�Ɏ���:����VO ��s�擾     * //
    // ************************************* //
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1�s�ڂ��擾
      OARow resultsSearchVoRow = (OARow)resultsSearchVo.first();
      // �L�[�ɒl���Z�b�g
      resultsSearchVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchVoRow.setAttribute("RowKey", new Number(1));
      resultsSearchVoRow.setAttribute("PeopleCode", peopleCode);
      resultsSearchVoRow.setAttribute("ActualFlg", actualFlag);
      resultsSearchVoRow.setAttribute("ProductFlg", productFlag);
      resultsSearchVoRow.setAttribute("UpdateFlag", updateFlag);
    }

    // ******************************************* //
    // *    ���o�Ɏ���:�����w�b�_VO ��s�擾     * //
    // ******************************************* //
    OAViewObject resultsSearchHdVo = getXxinvMovResultsHdSearchVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsSearchHdVo.isPreparedForExecution())
    {
      resultsSearchHdVo.setMaxFetchSize(0);
      resultsSearchHdVo.insertRow(resultsSearchHdVo.createRow());
      // 1�s�ڂ��擾
      OARow resultsSearchHdVoRow = (OARow)resultsSearchHdVo.first();
      // �L�[�ɒl���Z�b�g
      resultsSearchHdVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchHdVoRow.setAttribute("RowKey", new Number(1));
    }

    // ************************************* //
    // * ���o�Ɏ��уw�b�_:�o�^VO ��s�擾  * //
    // ************************************* //
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!movementResultsHdVo.isPreparedForExecution())
    {
      movementResultsHdVo.setWhereClauseParam(0,null);
      movementResultsHdVo.executeQuery();
      movementResultsHdVo.insertRow(movementResultsHdVo.createRow());
      // 1�s�ڂ��擾
      OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
      // �L�[�ɒl���Z�b�g
      movementResultsHdRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdRow.setAttribute("MovType", XxinvConstants.MOV_TYPE_1);
      movementResultsHdRow.setAttribute("NotifStatus", XxinvConstants.NOTIFSTATSU_CODE_1O);
      movementResultsHdRow.setAttribute("NotifStatusName", XxinvConstants.NOTIFSTATSU_NAME_1O);

      // ���i���ʋ敪��:1(���i)�̏ꍇ
      if ("1".equals(productFlag))
      {
        movementResultsHdRow.setAttribute("FreightChargeClass", XxinvConstants.FREIGHT_CHARGE_CLASS_1);
      } else if ("2".equals(productFlag))
      {
        movementResultsHdRow.setAttribute("FreightChargeClass", XxinvConstants.FREIGHT_CHARGE_CLASS_0);
      }

      // ���i�敪��:1���[�t�̏ꍇ
      if ("1".equals(itemClass))
      {
        movementResultsHdRow.setAttribute("WeightCapacityClass", XxinvConstants.WEIGHT_CAPACITY_CLASS_CODE_2);
        movementResultsHdRow.setAttribute("WeightCapacityClassName", XxinvConstants.WEIGHT_CAPACITY_CLASS_NAME_2);

      // ���i�敪��:2�h�����N�̏ꍇ
      } else if ("2".equals(itemClass))
      {
        movementResultsHdRow.setAttribute("WeightCapacityClass", XxinvConstants.WEIGHT_CAPACITY_CLASS_CODE_1);
        movementResultsHdRow.setAttribute("WeightCapacityClassName", XxinvConstants.WEIGHT_CAPACITY_CLASS_NAME_1);
      }

      // �X�V�t���O��NULL�̏ꍇ
      if (XxcmnUtility.isBlankOrNull(updateFlag))
      {
        // �����t���O 1:�o�^
        movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_I);
        // ���[�U���擾
        getUserData(actualFlag, "2");
      } else
      {
        // �����t���O 2:�X�V
        movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U);
      }
    }

    // ************************************* //
    // * ���o�Ɏ��уw�b�_:�o�^PVO ��s�擾 * //
    // ************************************* //
    OAViewObject movementResultsHdPvo = getXxinvMovementResultsHdPVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!movementResultsHdPvo.isPreparedForExecution())
    {
      movementResultsHdPvo.setMaxFetchSize(0);
      movementResultsHdPvo.insertRow(movementResultsHdPvo.createRow());
      // 1�s�ڂ��擾
      OARow movementResultsHdPvoRow = (OARow)movementResultsHdPvo.first();
      // �L�[�ɒl���Z�b�g
      movementResultsHdPvoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdPvoRow.setAttribute("RowKey", new Number(1));
    }
     
  } // initializeHdr

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̐V�K�s�}���������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void addRow()
  {
    //���o�Ɏ��уw�b�_:�o�^VO�擾
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();

    // *********************** //
    // *  �����ؑ֏���       * //
    // *********************** //
    // �����t���O 1:�o�^�̏ꍇ
    if (movementResultsHdRow.getAttribute("ProcessFlag").equals(XxinvConstants.PROCESS_FLAG_I))
    {
      disabledChanged("1"); // �K�p�𖳌��ɐݒ�
    } else
    {
      disabledChanged("0"); // �K�p��L���ɐݒ�
    }

    // *********************** //
    // *  ���͐��䏈��       * //
    // *********************** //
    readOnlyChanged("1");
     
  } // addRow

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̌����������s�����\�b�h�ł��B
   * @param searchHdrId  - �����p�����[�^�w�b�_ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchHdr(String searchHdrId) throws OAException
  {
    // ���o�Ɏ��уw�b�_:�o�^VO�擾
    XxinvMovementResultsHdVOImpl movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // ����
    movementResultsHdVo.initQuery(searchHdrId);         // �����p�����[�^�w�b�_ID
    // 1�s�߂��擾
    OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();

    // �f�[�^���擾�ł��Ȃ������ꍇ
    if (movementResultsHdVo.getRowCount() == 0)
    {
      // *********************** //
      // *  VO����������       * //
      // *********************** //
      OAViewObject vo = getXxinvMovementResultsHdVO1();
      vo.setWhereClauseParam(0,null);
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1�s�ڂ��擾
      OARow row = (OARow)vo.first();
      // �L�[�ɒl���Z�b�g
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("MovHdrId", new Number(-1));
      row.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_I);

      // *********************** //
      // *  �����ؑ֏���       * //
      // *********************** //
      disabledChanged("1"); // �K�p�𖳌��ɐݒ�

      // ************************ //
      // * �G���[���b�Z�[�W�o�� *
      // ************************ //
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);

    // �f�[�^���擾�ł����ꍇ
    } else
    { 

      movementResultsHdRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U); // �����t���O 2:�X�V
      // �o�ɓ�(����)�A����(����)���Z�b�g
      OAViewObject searchVo = getXxinvMovResultsSearchVO1();
      OARow searchVoRow = (OARow)searchVo.first();

      // �z��No���t�^����Ă���ꍇ
      if (!XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("DeliveryNo")))
      {
        // �o�ɓ�(����)��NULL�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualShipDate")))
        {
          // �o�ɓ����o�ɓ�(����)�փZ�b�g����
          movementResultsHdRow.setAttribute("ActualShipDate", movementResultsHdRow.getAttribute("ScheduleShipDate"));
        }
        // ����(����)��NULL�̏ꍇ
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualArrivalDate")))
        {
          // �����𒅓�(����)�փZ�b�g����
          movementResultsHdRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ScheduleArrivalDate"));
        }
// 2008-09-24 H.Itou add Start �����e�X�g�w�E59 �o�Ɏ��ѓ����Ȃ��ꍇ�A�o�ɗ\������o�Ɏ��ѓ��ɕ\������B
      // �z��No���Ȃ��ꍇ
      } else
      { 
        String actualFlg = (String)searchVoRow.getAttribute("ActualFlg"); // ���уf�[�^�敪

        // �o�Ɏ��у��j���[�ŋN���̏ꍇ�ŁA�o�ɓ�(����)��NULL�̏ꍇ�A�o�ɗ\������R�s�[
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualShipDate"))
          && XxinvConstants.ACTUAL_FLAG_DELI.equals(actualFlg))
        {
          // �o�ɓ����o�ɓ�(����)�փZ�b�g����
          movementResultsHdRow.setAttribute("ActualShipDate", movementResultsHdRow.getAttribute("ScheduleShipDate"));
        }
        // ���Ɏ��у��j���[�ŋN���̏ꍇ�ŁA����(����)��NULL�̏ꍇ�A���ח\������R�s�[
        if (XxcmnUtility.isBlankOrNull(movementResultsHdRow.getAttribute("ActualArrivalDate"))
          && XxinvConstants.ACTUAL_FLAG_SCOC.equals(actualFlg))
        {
          // �����𒅓�(����)�փZ�b�g����
          movementResultsHdRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ScheduleArrivalDate"));
        }
// 2008-09-24 H.Itou add End
      }

      searchVoRow.setAttribute("ActualShipDate", movementResultsHdRow.getAttribute("ActualShipDate"));
      searchVoRow.setAttribute("ActualArrivalDate", movementResultsHdRow.getAttribute("ActualArrivalDate"));
      // �ړ��w�������A�o�Ɍ��A���ɐ�A�^���Ǝ҂̖��̂��Z�b�g
      OAViewObject searchHdVo = getXxinvMovResultsHdSearchVO1();
      OARow searchHdVoRow = (OARow)searchHdVo.first();
      searchHdVoRow.setAttribute("LocationName", movementResultsHdRow.getAttribute("LocationShortName"));
      searchHdVoRow.setAttribute("ShipLocationName", movementResultsHdRow.getAttribute("Description1"));
      searchHdVoRow.setAttribute("ArrivalLocationName", movementResultsHdRow.getAttribute("Description2"));
      searchHdVoRow.setAttribute("FrtCarrierName", movementResultsHdRow.getAttribute("PartyName2"));

      // *********************** //
      // *  �����ؑ֏���       * //
      // *********************** //
      disabledChanged("0"); // �K�p��L���ɐݒ�

      // *********************** //
      // *  ���͐��䏈��       * //
      // *********************** //
      readOnlyChanged("2");
    }
  } // doSearchHdr

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̏o�ɓ�(����)�̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyActualShipDate()
  {
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow row            = (OARow)vo.first();
    Date  actualShipDate = (Date)row.getAttribute("ActualShipDate");

    // �o�ɓ�(����)���o�ɓ��ɃR�s�[
    row.setAttribute("ScheduleShipDate", actualShipDate);
    
  } // copyActualShipDate

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̒���(����)�̃R�s�[�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void copyActualArrivalDate()
  {
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow row               = (OARow)vo.first();
    Date  actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate");

    // ����(����)�𒅓��ɃR�s�[
    row.setAttribute("ScheduleArrivalDate", actualArrivalDate);
    
  } // copyActualArrivalDate

  /***************************************************************************
   * �^���Ǝҍ��ڂ���͉\�ɂ��郁�\�b�h�ł��B
   ***************************************************************************
   */
  public void inputFreightCarrier()
  {
    // ���o�Ɏ��уw�b�_:�o�^PVO�擾
    OAViewObject resultsHdrPVO = getXxinvMovementResultsHdPVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)resultsHdrPVO.first();

    // �w�b�_.�^���Ǝ҂���͉\�ɕύX
    readOnlyRow.setAttribute("FreightCarrierReadOnly", Boolean.FALSE);
    
  } // inputFreightCarrier

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̍��ړ��e�̃N���A�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void clearValue()
  {
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow  row                = (OARow)vo.first();
    String freightChargeClass = (String)row.getAttribute("FreightChargeClass");

    // �^���敪��OFF�ɂȂ����ꍇ
    if ("0".equals(freightChargeClass))
    {
    // mod start ver1.5
      // �^���Ǝ�(����)���e���N���A
//      row.setAttribute("ActualCareerId", null);
//      row.setAttribute("ActualFreightCarrierCode", null);
//      row.setAttribute("PartyName2", null);
    // mod end ver1.5
      // �z���敪���N���A
      row.setAttribute("ShippingMethodCode", null);
      row.setAttribute("ShippingMethodName", null);
    }
  } // clearValue

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̓o�^�E�X�V���̃`�F�b�N���s���܂��B
   ***************************************************************************
   */
  public void checkHdr()
// 2008-09-24 H.Itou Add Start
     throws OAException
// 2008-09-24 H.Itou Add End
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow  row      = (OARow)vo.first();
    String movNum        = (String)row.getAttribute("MovNum");        // �ړ��ԍ�
    String movType       = (String)row.getAttribute("MovType");       // �ړ��^�C�v
    String compActualFlg = (String)row.getAttribute("CompActualFlg"); // ���ьv��t���O
// 2008-09-24 H.Itou Add Start �����e�X�g�w�E156 �o�Ɍ��E���ɐ擯��`�F�b�N
    String shippedLocat  = (String)row.getAttribute("ShippedLocatCode"); // �o�Ɍ��ۊǏꏊ
    String shipToLocat   = (String)row.getAttribute("ShipToLocatCode");  // ���ɐ�ۊǏꏊ
    // ���уf�[�^�敪VO�擾
    OAViewObject resultSearchVo = getXxinvMovResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow  resultSearchRow = (OARow)resultSearchVo.first(); 
    String actualFlg       = (String)resultSearchRow.getAttribute("ActualFlg"); // ���уf�[�^�敪
// 2008-09-24 H.Itou Add End

    // �ړ��ԍ����ݒ�ς��ړ��^�C�v���u�ϑ��Ȃ��v�����ьv��ς̏ꍇ
    if ((!XxcmnUtility.isBlankOrNull(movNum))
           && (XxinvConstants.MOV_TYPE_2.equals(movType))
           && (XxinvConstants.COMP_ACTUAL_FLG_Y.equals(compActualFlg)))
    {
      // �X�V�`�F�b�N
      chkActualTypeOn(vo, row, exceptions);

      // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // �ړ��ԍ����ݒ�ς��ړ��^�C�v���u�ϑ�����v�����ьv��ς̏ꍇ
    } else if ((!XxcmnUtility.isBlankOrNull(movNum))
                  && (XxinvConstants.MOV_TYPE_1.equals(movType))
                  && (XxinvConstants.COMP_ACTUAL_FLG_Y.equals(compActualFlg)))
    {
      // �X�V�`�F�b�N
      chkActualTypeOff(vo, row, exceptions);

      // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // �w������V�K�o�^(�ړ��ԍ����ݒ��)�ꍇ
    } else if ((!XxcmnUtility.isBlankOrNull(movNum))
                  && (XxinvConstants.COMP_ACTUAL_FLG_N.equals(compActualFlg)))
    {
      // �X�V�`�F�b�N
      chkInstr(vo, row, XxinvConstants.INPUT_FLAG_1, exceptions);

      // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }

    // �w���Ȃ��V�K�o�^(�ړ��ԍ������ݒ�)�ꍇ
    } else
    {
      // �X�V�`�F�b�N
      chkInstr(vo, row, XxinvConstants.INPUT_FLAG_2, exceptions);

      // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
      if (exceptions.size() > 0)
      {
        OAException.raiseBundledOAException(exceptions);
      }
    }

// 2008-09-24 H.Itou Add Start �����e�X�g�w�E156 �o�Ɍ��E���ɐ擯��`�F�b�N
    if (!XxcmnUtility.isBlankOrNull(shippedLocat)
     && !XxcmnUtility.isBlankOrNull(shipToLocat)
     && shippedLocat.equals(shipToLocat))
    {
      throw new OAException(XxcmnConstants.APPL_XXINV, XxinvConstants.XXINV10119);
    }
// 2008-09-24 H.Itou Add End
  } // checkHdr

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ�
   * �ړ��ԍ����ݒ��(���ђ���)���ړ��^�C�v�u�ϑ��Ȃ��v���̃`�F�b�N���s���܂��B
   * @param vo         �`�F�b�N�Ώ�VO
   * @param row        �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkActualTypeOn(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // ���擾
    Object actualShipDate    = row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Object actualArrivalDate = row.getAttribute("ActualArrivalDate"); // ����(����)

    // �o�ɓ�(����)�A����(����)�������̏ꍇ
    if (XxcmnUtility.isEquals(actualShipDate, actualArrivalDate))
    {
      // �o�ɓ�(����)�̖������`�F�b�N
      chkFutureDate(vo, row, "1", exceptions);

    // �o�ɓ�(����)�A����(����)�������łȂ��ꍇ�̓G���[
    } else
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10034,
                            tokens));

    }
  } // chkActualTypeOn

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ�
   * �ړ��ԍ����ݒ��(���ђ���)���ړ��^�C�v�u�ϑ�����v���̃`�F�b�N���s���܂��B
   * @param vo         �`�F�b�N�Ώ�VO
   * @param row        �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkActualTypeOff(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    // �X�e�[�^�X���擾
    String status = (String)row.getAttribute("Status");
    // ���ѓ����擾
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // ����(����)

    // �o�ɓ�(����) > ����(����)�̏ꍇ
    if (XxcmnUtility.chkCompareDate(1, actualShipDate, actualArrivalDate))
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[2];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10055,
                            tokens));

    // �o�ɓ�(����) <= ����(����)�̏ꍇ
    } else if (XxcmnUtility.chkCompareDate(2, actualArrivalDate, actualShipDate))
    {
      // ���уf�[�^�敪VO�擾
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1�s�ڂ��擾
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

      // �o�Ɏ��у��j���[����N�������ꍇ
      if ("1".equals(actualFlg))
      {
        // �X�e�[�^�X���u���ɕ񍐗L�v���́u���o�ɕ񍐗L�v�̏ꍇ
        if ((XxinvConstants.STATUS_05.equals(status))
              || (XxinvConstants.STATUS_06.equals(status)))
        {
          // �o�ɓ�(����)�A����(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "3", exceptions);
        } else
        {
          // �o�ɓ�(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "1", exceptions);
        }

      // ���Ɏ��у��j���[����N�������ꍇ
      } else if ("2".equals(actualFlg))
      {
        // �X�e�[�^�X���u�o�ɕ񍐗L�v���́u���o�ɕ񍐗L�v�̏ꍇ
        if ((XxinvConstants.STATUS_04.equals(status))
              || (XxinvConstants.STATUS_06.equals(status)))
        {
          // �o�ɓ�(����)�A����(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "3", exceptions);
        } else
        {
          // ����(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "2", exceptions);
        }
      }
    }
    
  } // chkActualTypeOff

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̎w���L�A�w�����̐V�K�o�^���̃`�F�b�N���s���܂��B
   * @param vo         �`�F�b�N�Ώ�VO
   * @param row        �`�F�b�N�Ώۍs
   * @param exeType    �w������:1�A�w������:2
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkInstr(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    int i = 0;
    // ���ѓ����擾
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // ����(����)
    
    // �����̓`�F�b�N
    String retCode = (String)chkUninput(vo, row, exeType, exceptions);

    // �����̓`�F�b�N������I���̏ꍇ
    if (XxcmnConstants.STRING_TRUE.equals(retCode))
    {
      // �o�ɓ�(����)�A ����(����)�����͍ς̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(actualShipDate)
            && !XxcmnUtility.isBlankOrNull(actualArrivalDate))
      {
        // �o�ɓ�(����) > ����(����)�̏ꍇ
        if (XxcmnUtility.chkCompareDate(1, actualShipDate, actualArrivalDate))
        {
          // �G���[���b�Z�[�W�g�[�N���擾
          MessageToken[] tokens = new MessageToken[2];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          tokens[1] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualShipDate",
                                actualShipDate,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10055,
                                tokens));

        }
      }
      // �o�ɓ�(����) <= ����(����)�̏ꍇ
      if (i == 0)
      {
        // ���уf�[�^�敪VO�擾
        OAViewObject actualVo = getXxinvMovResultsSearchVO1();
        // 1�s�ڂ��擾
        OARow  actualVoRow = (OARow)actualVo.first();
        String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

        // �o�Ɏ��у��j���[����N�������ꍇ
        if ("1".equals(actualFlg))
        {
          // �o�ɓ�(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "1", exceptions);

        // ���Ɏ��у��j���[����N�������ꍇ
        } else if ("2".equals(actualFlg))
        {
          // ����(����)�̖������`�F�b�N
          chkFutureDate(vo, row, "2", exceptions);
        }

        // �ۊǑq�ɂ̖����̓`�F�b�N
        chkLocat(vo, row, exeType,exceptions);
      }
    }
  } // chkInstr

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̕ۊǑq�ɂ̖����̓`�F�b�N���s���܂��B
   * @param vo         �`�F�b�N�Ώ�VO
   * @param row        �`�F�b�N�Ώۍs
   * @param exeType    �w������:1�A�w������:2
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkLocat(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    String shippedLocat = (String)row.getAttribute("ShippedLocatCode"); // �o�Ɍ��ۊǏꏊ
    String shipToLocat  = (String)row.getAttribute("ShipToLocatCode");  // ���ɐ�ۊǏꏊ
    String freightChargeClass  = (String)row.getAttribute("FreightChargeClass");  // �^���敪
    String weightCapacityClass  = (String)row.getAttribute("WeightCapacityClass");  // �d�͗e�ϋ敪
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)

    // mod start ver1.3
    // �w������V�K�o�^�̏ꍇ
    /*if (XxinvConstants.INPUT_FLAG_1.equals(exeType))
    {
      // ���уf�[�^�敪VO�擾
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1�s�ڂ��擾
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

      // �o�Ɏ��у��j���[����N�������ꍇ
      if ("1".equals(actualFlg))
      {
        // �o�Ɍ��ۊǏꏊ�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(shippedLocat))
        {
          // ���b�Z�[�W�擾
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShippedLocatCode",
                                shippedLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
        }

      // ���Ɏ��у��j���[����N�������ꍇ
      } else if ("2".equals(actualFlg))
      {
        // ���ɐ�ۊǏꏊ�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(shipToLocat))
        {
          // ���b�Z�[�W�擾
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShipToLocatCode",
                                shipToLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
        }
        
      }*/

    // �w���Ȃ��V�K�o�^�̏ꍇ
    //} else if (XxinvConstants.INPUT_FLAG_2.equals(exeType))
    if (XxinvConstants.INPUT_FLAG_2.equals(exeType))
    {
      // �o�Ɍ��ۊǏꏊ�������͂̏ꍇ
      /*if (XxcmnUtility.isBlankOrNull(shippedLocat))
      {
        // ���b�Z�[�W�擾
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShippedLocatCode",
                              shippedLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));

      // ���ɐ�ۊǏꏊ�������͂̏ꍇ
      } else if (XxcmnUtility.isBlankOrNull(shipToLocat))
      {
        // ���b�Z�[�W�擾
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShipToLocatCode",
                              shipToLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));
      }*/
      // �o�Ɍ��A���ɐ�ǂ�������͍ς��^���敪ON�̏ꍇ
      //if ((exceptions.size() == 0) && ("1".equals(freightChargeClass)))
      if ("1".equals(freightChargeClass))
      // mod start ver1.3
      {
        // �ő�z���敪���Z�o����
        HashMap paramsRet = XxinvUtility.getMaxShipMethod(
                              getOADBTransaction(),
                              "4", // �q��
                              shippedLocat,
                              "4", // �q��
                              shipToLocat,
                              weightCapacityClass,
                              null,
                              actualShipDate);

        // �ő�z���敪���擾�ł��Ȃ������ꍇ
        if (XxcmnUtility.isBlankOrNull(paramsRet.get("maxShipMethods"))) 
        {
          // �G���[���b�Z�[�W�o��
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_MSG, XxinvConstants.TOKEN_NAME_MAX_SHIP_METHOD);
          throw new OAAttrValException(
                      OAAttrValException.TYP_VIEW_OBJECT,
                      vo.getName(),
                      row.getKey(),
                      "ShipToLocatCode",
                      shipToLocat,
                      XxcmnConstants.APPL_XXINV,
                      XxinvConstants.XXINV10009,
                      tokens);
        } else 
        {
          // �z���敪�ɃZ�b�g
          row.setAttribute("ActualShippingMethodCode", paramsRet.get("maxShipMethods"));
        }
        
      }
    }
  } // chkLocat

  /***************************************************************************
   * ���o�Ɏ��ѕK�{���ڂ̖����̓`�F�b�N���s���܂��B
   * @param vo         �`�F�b�N�Ώ�VO
   * @param row        �`�F�b�N�Ώۍs
   * @param exeType    �w������:1�A�w������:2
   * @param exceptions �G���[���X�g
   * @return String    ����:TRUE�A�ُ�:FALSE
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String chkUninput(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    String retCode = XxcmnConstants.STRING_TRUE;
    // ���ѓ����擾
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // ����(����)
    // add start ver1.3
    // �ۊǏꏊ���擾
    String shippedLocat    = (String)row.getAttribute("ShippedLocatCode"); // �o�Ɍ��ۊǏꏊ
    String shipToLocat     = (String)row.getAttribute("ShipToLocatCode");  // ���ɐ�ۊǏꏊ
    // add end ver1.3
    

    // �w������V�K�o�^�̏ꍇ
    if (XxinvConstants.INPUT_FLAG_1.equals(exeType))
    {
      // ���уf�[�^�敪VO�擾
      OAViewObject actualVo = getXxinvMovResultsSearchVO1();
      // 1�s�ڂ��擾
      OARow  actualVoRow = (OARow)actualVo.first(); 
      String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

      // �o�Ɏ��у��j���[����N�������ꍇ
      if ("1".equals(actualFlg))
      {
        // add start ver1.3
        // �o�Ɍ��ۊǏꏊ�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(shippedLocat))
        {
          // ���b�Z�[�W�擾
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShippedLocatCode",
                                shippedLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
          retCode = XxcmnConstants.STRING_FALSE;
        }
        // add end ver1.3
        // �o�ɓ�(����)�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(actualShipDate))
        {
          // �G���[���b�Z�[�W�g�[�N���擾
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualShipDate",
                                actualShipDate,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10131,
                                tokens));
          retCode = XxcmnConstants.STRING_FALSE;
        }

      // ���Ɏ��у��j���[����N�������ꍇ
      } else if ("2".equals(actualFlg))
      {
        // add start ver1.3
        // ���ɐ�ۊǏꏊ�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(shipToLocat))
        {
          // ���b�Z�[�W�擾
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ShipToLocatCode",
                                shipToLocat,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10064,
                                null));
          retCode = XxcmnConstants.STRING_FALSE;
        }
        // add end ver1.3
        // ����(����)�������͂̏ꍇ
        if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
        {
          // �G���[���b�Z�[�W�g�[�N���擾
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                vo.getName(),
                                row.getKey(),
                                "ActualArrivalDate",
                                actualArrivalDate,
                                XxcmnConstants.APPL_XXINV,
                                XxinvConstants.XXINV10131,
                                tokens));
          retCode = XxcmnConstants.STRING_FALSE;
        }
      }
      
    // �w���Ȃ��V�K�o�^�̏ꍇ
    } else
    {
      // add start ver1.3
      // �o�Ɍ��ۊǏꏊ�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(shippedLocat))
      {
        // ���b�Z�[�W�擾
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShippedLocatCode",
                              shippedLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));
        retCode = XxcmnConstants.STRING_FALSE;

      }
      // ���ɐ�ۊǏꏊ�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(shipToLocat))
      {
        // ���b�Z�[�W�擾
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ShipToLocatCode",
                              shipToLocat,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10064,
                              null));
        retCode = XxcmnConstants.STRING_FALSE;
      }
      // add end ver1.3
      // �o�ɓ�(����)�������͂̏ꍇ
      if (XxcmnUtility.isBlankOrNull(actualShipDate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10131,
                              tokens));
        retCode = XxcmnConstants.STRING_FALSE;

      // ����(����)�������͂̏ꍇ
      // mod start ver1.3
      //} else if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
      }
      if (XxcmnUtility.isBlankOrNull(actualArrivalDate))
      // mod end ver1.3
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10131,
                              tokens));
        retCode = XxcmnConstants.STRING_FALSE;
      }
    }

    return retCode;
  } // chkUninput

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̖������̃`�F�b�N���s���܂��B
   * @param vo        �`�F�b�N�Ώ�VO
   * @param row       �`�F�b�N�Ώۍs
   * @param exeType   �o�ɓ�(����)���`�F�b�N:1�A����(����)���`�F�b�N:2�A�����`�F�b�N:3
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkFutureDate(
    OAViewObject vo,
    OARow row,
    String exeType,
    ArrayList exceptions
  ) throws OAException
  {
    // SYSDATE���擾
    Date sysdate = XxinvUtility.getSysdate(getOADBTransaction());

    // ���ѓ����擾
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // ����(����)

    // �������G���[�J�E���g
    int errCount = 0;

    // �o�ɓ�(����)���`�F�b�N����ꍇ
    if ("1".equals(exeType))
    {

      // �o�ɓ�(����)���������̏ꍇ
      if (XxcmnUtility.chkCompareDate(1, actualShipDate, sysdate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10066,
                              tokens));
        // �G���[���J�E���g
        errCount = errCount + 1;

      }

    // ����(����)���`�F�b�N����ꍇ
    } else if ("2".equals(exeType))
    {
      // ����(����)���������̏ꍇ
      if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, sysdate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10067,
                              tokens));
        // �G���[���J�E���g
        errCount = errCount + 1;
      }

    // �o�ɓ�(����)�A����(����)�̗������`�F�b�N����ꍇ
    } else if ("3".equals(exeType))
    {
      // �o�ɓ�(����)���������̏ꍇ
      if (XxcmnUtility.chkCompareDate(1, actualShipDate, sysdate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_SHIP_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualShipDate",
                              actualShipDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10066,
                              tokens));
        // �G���[���J�E���g
        errCount = errCount + 1;

      // ����(����)���������̏ꍇ
      } else if (XxcmnUtility.chkCompareDate(1, actualArrivalDate, sysdate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxinvConstants.TOKEN_ARRIVAL_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              vo.getName(),
                              row.getKey(),
                              "ActualArrivalDate",
                              actualArrivalDate,
                              XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10067,
                              tokens));
        // �G���[���J�E���g
        errCount = errCount + 1;
      }
    }
    // �������łȂ��ꍇ
    if (errCount == 0)
    {
      // OPM�݌ɃN���[�Y�`�F�b�N
      stockCloseCheck(vo, row, exceptions);
    }
  } // chkFutureDate

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ�OPM�݌ɃN���[�Y�`�F�b�N���s�����\�b�h�ł��B
   * @param vo        �`�F�b�N�Ώ�VO
   * @param row       �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void stockCloseCheck(
    OAViewObject vo,
    OARow row,
    ArrayList exceptions
  ) throws OAException
  {
    //���ѓ����擾
    Date actualShipDate    = (Date)row.getAttribute("ActualShipDate");    // �o�ɓ�(����)
    Date actualArrivalDate = (Date)row.getAttribute("ActualArrivalDate"); // ����(����)

    // �݌ɃN���[�Y�`�F�b�N:�o�ɓ�(����)
    if (XxinvUtility.chkStockClose(
          getOADBTransaction(), // �g�����U�N�V����
          actualShipDate)       // �o�ɓ�(����)
        )
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[1];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_SHIP_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualShipDate",
                            actualShipDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10120,
                            tokens));

    }
    // �݌ɃN���[�Y�`�F�b�N:����(����)
    if (XxinvUtility.chkStockClose(
          getOADBTransaction(), // �g�����U�N�V����
          actualArrivalDate)    // ����(����)
        )
    {
      // �G���[���b�Z�[�W�g�[�N���擾
      MessageToken[] tokens = new MessageToken[1];
      tokens[0] = new MessageToken(XxinvConstants.TOKEN_TARGET_DATE, XxinvConstants.TOKEN_NAME_ARRIVAL_DATE);
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "ActualArrivalDate",
                            actualArrivalDate,
                            XxcmnConstants.APPL_XXINV,
                            XxinvConstants.XXINV10120,
                            tokens));

    }
  } // stockCloseCheck

  /****************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̉ғ����`�F�b�N���s�����\�b�h�ł��B
   * @return String ���^�[���R�[�h(����(�X�V��)�FTRUE�A
   *           �G���[(�o�Ɏ��у��j���[�N��)�F1�A�G���[(���Ɏ��у��j���[�N��)�F2)
   * @throws OAException - OA��O
   ****************************************************************************
   */
  public String oprtnDayCheck() throws OAException
  {
    String retCode = XxcmnConstants.STRING_TRUE;
    // IN�p�����[�^
    Date   originalDate = null; // ���
    String shipWhseCode = null; // �ۊǑq�ɃR�[�h
    // �߂�l
    Date   oprtnDay;
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow  row      = (OARow)vo.first();

    // ���уf�[�^�敪VO�擾
    OAViewObject actualVo = getXxinvMovResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow  actualVoRow = (OARow)actualVo.first(); 
    String actualFlg   = (String)actualVoRow.getAttribute("ActualFlg");

    // �o�Ɏ��у��j���[����N�������ꍇ
    if ("1".equals(actualFlg))
    {
      // �p�����[�^�ݒ�
    originalDate = (Date)row.getAttribute("ActualShipDate");     // �o�ɓ�(����)
    shipWhseCode = (String)row.getAttribute("ShippedLocatCode"); // �o�Ɍ�
    retCode = actualFlg;

    // ���Ɏ��у��j���[����N�������ꍇ
    } else if ("2".equals(actualFlg))
    {
      // �p�����[�^�ݒ�
      originalDate = (Date)row.getAttribute("ActualArrivalDate");  // ����(����)
      shipWhseCode = (String)row.getAttribute("ShipToLocatCode");  // ���ɐ�
      retCode = actualFlg;
    }
    // �ғ����`�F�b�N
    oprtnDay = XxinvUtility.getOprtnDay(
                 getOADBTransaction(),
                 originalDate,
                 shipWhseCode,
                 null,
                 0);

    if (XxcmnUtility.isBlankOrNull(oprtnDay))
    {
      return retCode;
    }
    return XxcmnConstants.STRING_TRUE;
  } // oprtnDayCheck

  /***************************************************************************
   * �R���J�����g�F�ړ����o�Ɏ��ѓo�^�����ł��B
   * @return HashMap - ���^�[���R�[�h
   ***************************************************************************
   */
  public HashMap doMovActualMake()
  {
    // �ړ��ԍ����擾
    OAViewObject vo = getXxinvMovementResultsHdVO1();
    OARow row       = (OARow)vo.first();
    String movNum   = (String)row.getAttribute("MovNum");


    // IN�p�����[�^�pHashMap����
    HashMap inParams = new HashMap();
    inParams.put("MovNum", movNum);

    // �ړ����o�Ɏ��ѓo�^�������s
    return XxinvUtility.doMovShipActualMake(
                          getOADBTransaction(), // �g�����U�N�V����
                          inParams              // �p�����[�^
                          );
  } // doMovActualMake

  /***************************************************************************
   * �p���b�g����(�o/��)�̃`�F�b�N���\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chckPallet() throws OAException
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);

    OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow       = (OARow)hdrVo.first();
    // �p���b�g����������X�V���ꂽ�ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("CollectedPalletQty"),
          hdrRow.getAttribute("DbCollectedPalletQty")))
    {
      Object collectedPalletQty = hdrRow.getAttribute("CollectedPalletQty");
      // �p���b�g��������ɒl�����͂���Ă���ꍇ
      if (!XxcmnUtility.isBlankOrNull(collectedPalletQty))
      {
        // ���l(999)�łȂ��ꍇ�̓G���[
        if (!XxcmnUtility.chkNumeric(collectedPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "CollectedPalletQty",
                  collectedPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));
        } else 
        {
          // �}�C�i�X�l�̓G���[
          if (!XxcmnUtility.chkCompareNumeric(2, collectedPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,
                    hdrVo.getName(),
                    hdrRow.getKey(),
                    "CollectedPalletQty",
                    collectedPalletQty,
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10030));
          }
        }
      }
    }
    // �p���b�g����(�o)���X�V���ꂽ�ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("OutPalletQty"),
          hdrRow.getAttribute("DbOutPalletQty")))
    {
      Object outPalletQty = hdrRow.getAttribute("OutPalletQty");
      // �p���b�g����(�o)�ɒl�����͂���Ă���ꍇ
      if (!XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        // ���l(999)�łȂ��ꍇ�̓G���[
        if (!XxcmnUtility.chkNumeric(outPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "OutPalletQty",
                  outPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));

        } else 
        {
          // �}�C�i�X�l�̓G���[
          if (!XxcmnUtility.chkCompareNumeric(2, outPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                OAAttrValException.TYP_VIEW_OBJECT,
                hdrVo.getName(),
                hdrRow.getKey(),
                "OutPalletQty",
                outPalletQty,
                XxcmnConstants.APPL_XXINV,
                XxinvConstants.XXINV10030));
          }
        }
      }
      
    }
    // �p���b�g����(��)���X�V���ꂽ�ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("InPalletQty"),
          hdrRow.getAttribute("DbInPalletQty")))
    {
      Object inPalletQty = hdrRow.getAttribute("InPalletQty");
      // �p���b�g����(��)�ɒl�����͂���Ă���ꍇ
      if (!XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        // ���l(999)�łȂ��ꍇ�̓G���[
        if (!XxcmnUtility.chkNumeric(inPalletQty, 3, 0)) 
        {
          exceptions.add(
            new OAAttrValException(
                  OAAttrValException.TYP_VIEW_OBJECT,
                  hdrVo.getName(),
                  hdrRow.getKey(),
                  "InPalletQty",
                  inPalletQty,
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10160));

        } else 
        {
          // �}�C�i�X�l�̓G���[
          if (!XxcmnUtility.chkCompareNumeric(2, inPalletQty, "0"))
          {
            exceptions.add(
              new OAAttrValException(
                    OAAttrValException.TYP_VIEW_OBJECT,
                    hdrVo.getName(),
                    hdrRow.getKey(),
                    "InPalletQty",
                    inPalletQty,
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10030));
          }
        }
      }
    }
    // �G���[������ꍇ�A�C�����C�����b�Z�[�W�o��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }
  } // chckPallet

  /***************************************************************************
   * ���o�Ɏ��уw�b�_�̍X�V�������s�����\�b�h�ł��B
   * @return String ���^�[���R�[�h(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
   ***************************************************************************
   */
  public String UpdateHdr()
  {
    //
    String retCode  = XxcmnConstants.STRING_TRUE;
    String updFlag  = XxcmnConstants.STRING_N;

    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    OARow makeHdrVORow = (OARow)makeHdrVO.first();
    Number movHdrId = (Number)makeHdrVORow.getAttribute("MovHdrId");

    // *************************** //
    // *   �w�b�_�[�X�V����      * //
    // *************************** //
    if ((!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                         makeHdrVORow.getAttribute("DbActualShipDate")))           // �o�ɓ�(����)�F�o�ɓ�(����)(DB)
           || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                               makeHdrVORow.getAttribute("DbActualArrivalDate")))  // ����(����)�F����(����)(DB)
           || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                               makeHdrVORow.getAttribute("DbOutPalletQty")))       // �p���b�g����(�o)�F�p���b�g����(�o)(DB)
           || (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                               makeHdrVORow.getAttribute("DbInPalletQty"))))       // �p���b�g����(��)�F�p���b�g����(��)(DB)
    {
      // ���ьv��σt���O��Y�̏ꍇ
      if (XxcmnConstants.STRING_Y.equals(makeHdrVORow.getAttribute("CompActualFlg")))
      {
        makeHdrVORow.setAttribute("CorrectActualFlg", XxcmnConstants.STRING_Y);
      }
      // �ړ��˗�/�w���w�b�_(�A�h�I��)�X�V����
      retCode = headerUpdate(makeHdrVORow);

      // �w�b�_�X�V�����ŃG���[�����������ꍇ�A�����𒆒f
      if (XxcmnConstants.STRING_FALSE.equals(retCode))
      {
        return retCode;
      }
      // �o�ɓ�(����)���X�V���ꂽ�ꍇ
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
            makeHdrVORow.getAttribute("DbActualShipDate")))
      {
        // �o�ɓ�(����)(DB)�ɍX�V�����l���Z�b�g
  //      makeHdrVORow.setAttribute("DbActualShipDate", makeHdrVORow.getAttribute("ActualShipDate"));
        // ���b�g�ڍ׊m�F����
        if (XxinvUtility.chkLotDetails(
                           getOADBTransaction(),         // �g�����U�N�V����
                           movHdrId,                     // �ړ��w�b�_ID
                           XxinvConstants.RECORD_TYPE_20 // ���R�[�h�^�C�v
                           )
           )
        {
          // �ړ����b�g�ڍ׎��s���̍X�V����
          retCode = lotUpdate(makeHdrVORow, XxinvConstants.RECORD_TYPE_20);
        }

      }
      // ����(����)���X�V���ꂽ�ꍇ
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
            makeHdrVORow.getAttribute("DbActualArrivalDate")))
      {
        // ����(����)(DB)�ɍX�V�����l���Z�b�g
  //      makeHdrVORow.setAttribute("DbActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));
        // ���b�g�ڍ׊m�F����
        if (XxinvUtility.chkLotDetails(
                           getOADBTransaction(),         // �g�����U�N�V����
                           movHdrId,                     // �ړ��w�b�_ID
                           XxinvConstants.RECORD_TYPE_30 // ���R�[�h�^�C�v
                           )
          )
        {
          // �ړ����b�g�ڍ׎��s���̍X�V����
          retCode = lotUpdate(makeHdrVORow, XxinvConstants.RECORD_TYPE_30);
        }
      }
      // �p���b�g����(�o)���X�V���ꂽ�ꍇ
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
            makeHdrVORow.getAttribute("DbOutPalletQty")))
      {
        // �p���b�g����(�o)(DB)�ɍX�V�����l���Z�b�g
        makeHdrVORow.setAttribute("DbOutPalletQty", makeHdrVORow.getAttribute("OutPalletQty"));
      }
      // �p���b�g����(��)���X�V���ꂽ�ꍇ
      if (!XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
            makeHdrVORow.getAttribute("DbInPalletQty")))
      {
        // �p���b�g����(��)(DB)�ɍX�V�����l���Z�b�g
        makeHdrVORow.setAttribute("DbInPalletQty", makeHdrVORow.getAttribute("InPalletQty"));
      }
      

      updFlag = XxcmnConstants.STRING_Y;
    }

    // �X�V����������ɏI�������ꍇ�A�Č����p�Ɉړ��w�b�_ID��߂�
    if (XxcmnConstants.STRING_Y.equals(updFlag))
    {
      retCode = XxcmnUtility.stringValue(movHdrId);


    // �X�V�����I�������ꍇ�ASTRING_TRUE��߂�
    } else
    {
      retCode = XxcmnConstants.STRING_TRUE;
    }
    return retCode;
  } // UpdateHdr

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̈ړ��˗�/�w���w�b�_UPDATE�������s�����\�b�h�ł��B
   * @param makeHdrVORow �X�V�Ώۍs
   * @return String ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String headerUpdate(OARow makeHdrVORow)
  {
    // �ړ��˗�/�w���w�b�_VO�f�[�^�擾
    HashMap params = new HashMap();

    // �ړ��w�b�_ID
    params.put("MovHdrId", makeHdrVORow.getAttribute("MovHdrId"));

    // �o�ɓ�(����)
    params.put("ActualShipDate", makeHdrVORow.getAttribute("ActualShipDate"));

    // ����(����)
    params.put("ActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));

    // �p���b�g����(�o)
    params.put("OutPalletQty", makeHdrVORow.getAttribute("OutPalletQty"));

    // �p���b�g����(��)
    params.put("InPalletQty", makeHdrVORow.getAttribute("InPalletQty"));

    // �^���Ǝ�_ID_����
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualCareerId")))
    {
      // �^���Ǝ�ID���Z�b�g
      params.put("ActualCareerId", makeHdrVORow.getAttribute("CareerId"));
    } else
    {
      // �^���Ǝ�_ID_���т��Z�b�g
      params.put("ActualCareerId", makeHdrVORow.getAttribute("ActualCareerId"));
    }

    // �^���Ǝ�_����
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualFreightCarrierCode")))
    {
      // �^���Ǝ҂��Z�b�g
      params.put("ActualFreightCarrierCode", makeHdrVORow.getAttribute("FreightCarrierCode"));
    } else
    {
      // �^���Ǝ�_���т��Z�b�g
      params.put("ActualFreightCarrierCode", makeHdrVORow.getAttribute("ActualFreightCarrierCode"));
    }

    // �z���敪_����
    if (XxcmnUtility.isBlankOrNull(makeHdrVORow.getAttribute("ActualShippingMethodCode")))
    {
      // �z���敪���Z�b�g
      params.put("ActualShippingMethodCode", makeHdrVORow.getAttribute("ShippingMethodCode"));
    } else
    {
      // �z���敪_���т��Z�b�g
      params.put("ActualShippingMethodCode", makeHdrVORow.getAttribute("ActualShippingMethodCode"));
    }

    // ���׎���FROM
    params.put("ArrivalTimeFrom", makeHdrVORow.getAttribute("ArrivalTimeFrom"));

    // ���׎���TO
    params.put("ArrivalTimeTo", makeHdrVORow.getAttribute("ArrivalTimeTo"));

    // ���ђ����t���O
    params.put("CorrectActualFlg", makeHdrVORow.getAttribute("CorrectActualFlg"));

    // �ŏI�X�V��
    params.put("LastUpdateDate", makeHdrVORow.getAttribute("LastUpdateDate"));

    // ���b�N�E�r������
    chkLockAndExclusive(params);

    // �ړ��˗�/�w���w�b�_�[�X�V�F���s
    String retCode =  XxinvUtility.updateMovReqInsrtHdr(
                        getOADBTransaction(), // �g�����U�N�V����
                        params                // �p�����[�^
                        );

    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }
    
    return XxcmnConstants.STRING_TRUE;
  } // headerUpdate

  /***************************************************************************
   * ���o�Ɏ��уw�b�_��ʂ̈ړ��˗�/�w���w�b�_���b�N�E�r���������s�����\�b�h�ł��B
   * @param params - �����p�p�����[�^
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void chkLockAndExclusive(
    HashMap params
  ) throws OAException
  {
    // ���b�N���擾���܂�
    Number headerId = (Number)params.get("MovHdrId");

    if (!XxinvUtility.getMovReqInstrHdrLock(getOADBTransaction(), headerId))
    {
      XxinvUtility.rollBack(getOADBTransaction());
      // ���b�N�G���[���b�Z�[�W
      throw new OAException(XxcmnConstants.APPL_XXINV,
                              XxinvConstants.XXINV10159);
    }

    // �r���`�F�b�N�����܂�
    String lastUpdateDate = (String)params.get("LastUpdateDate");
    if (!XxinvUtility.chkExclusiveMovReqInstrHdr(getOADBTransaction(), 
                        headerId,
                        lastUpdateDate))
    {
      XxinvUtility.rollBack(getOADBTransaction());
      // �r���G���[���b�Z�[�W
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
    }
  } // chkLockAndExclusive

  /***************************************************************************
   * �ړ����b�g�ڍ�(�A�h�I��)���ѓ���UPDATE�������s�����\�b�h�ł��B
   * @param makeHdrVORow �X�V�Ώۍs
   * @param recordType �@���R�[�h�^�C�v
   * @return String ����FTRUE�A�G���[�FFALSE
   ***************************************************************************
   */
  public String lotUpdate(
    OARow makeHdrVORow,
    String recordType)
  {
    // �ړ��˗�/�w���w�b�_VO�f�[�^�擾
    HashMap params = new HashMap();

    // �ړ��w�b�_ID
    params.put("MovHdrId", makeHdrVORow.getAttribute("MovHdrId"));

    // ���R�[�h�^�C�v
    params.put("RecordType", recordType);
    
    // �o�ɓ�(����)
    params.put("ActualShipDate", makeHdrVORow.getAttribute("ActualShipDate"));

    // ����(����)
    params.put("ActualArrivalDate", makeHdrVORow.getAttribute("ActualArrivalDate"));


    // �ړ����b�g�ڍ�(�A�h�I��)�X�V�F���s
    String retCode =  XxinvUtility.updateMovLotDetails(
                        getOADBTransaction(), // �g�����U�N�V����
                        params                // �p�����[�^
                        );

    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }
    
    return XxcmnConstants.STRING_TRUE;
  } // lotUpdate

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̏������������s�����\�b�h�ł��B
   * @param searchParams - �p�����[�^HashMap
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void initializeLine(
    HashMap searchParams
  ) throws OAException
  {
    // �p�����[�^�擾
    String peopleCode  = (String)searchParams.get(XxinvConstants.URL_PARAM_PEOPLE_CODE);
    String actualFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_ACTUAL_FLAG);
    String productFlag = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);
    String updateFlag  = (String)searchParams.get(XxinvConstants.URL_PARAM_UPDATE_FLAG);

    // ************************************* //
    // * ���o�Ɏ��уw�b�_:�o�^VO ��s�擾  * //
    // ************************************* //
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!movementResultsHdVo.isPreparedForExecution())
    {
      movementResultsHdVo.setWhereClauseParam(0,null);
      movementResultsHdVo.executeQuery();
      movementResultsHdVo.insertRow(movementResultsHdVo.createRow());
      // 1�s�ڂ��擾
      OARow movementResultsHdRow = (OARow)movementResultsHdVo.first();
      // �L�[�ɒl���Z�b�g
      movementResultsHdRow.setNewRowState(OARow.STATUS_INITIALIZED);
      movementResultsHdRow.setAttribute("MovHdrId", new Number(-1));
    }
    
    // ************************************* //
    // * ���o�Ɏ��і���:�o�^VO ��s�擾    * //
    // ************************************* //
    OAViewObject lnVo = getXxinvMovementResultsLnVO1();
    lnVo.setWhereClauseParam(0,null);
    lnVo.setWhereClauseParam(1,null);
    lnVo.setWhereClauseParam(2,null);
    lnVo.setWhereClauseParam(3,null);
// 2008/08/21 v1.6 Y.Yamamoto Mod Start
//    lnVo.setWhereClauseParam(4, null);
//    lnVo.setWhereClauseParam(5, null);
    lnVo.setWhereClauseParam(4,null);
// 2008/08/21 v1.6 Y.Yamamoto Mod End
    lnVo.executeQuery();

    addRowLine();

    // ************************************* //
    // *    ���o�Ɏ���:����VO ��s�擾     * //
    // ************************************* //
    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!resultsSearchVo.isPreparedForExecution())
    {
      resultsSearchVo.setMaxFetchSize(0);
      resultsSearchVo.insertRow(resultsSearchVo.createRow());
      // 1�s�ڂ��擾
      OARow resultsSearchVoRow = (OARow)resultsSearchVo.first();
      // �L�[�ɒl���Z�b�g
      resultsSearchVoRow.setNewRowState(OARow.STATUS_INITIALIZED);
      resultsSearchVoRow.setAttribute("RowKey", new Number(1));
      resultsSearchVoRow.setAttribute("PeopleCode", peopleCode);
      resultsSearchVoRow.setAttribute("ActualFlg", actualFlag);
      resultsSearchVoRow.setAttribute("ProductFlg", productFlag);
      resultsSearchVoRow.setAttribute("UpdateFlag", updateFlag);
      resultsSearchVoRow.setAttribute("ExeFlag", null);
    } else
    {
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      resultsSearchRow.setAttribute("ExeFlag", "1");
    }
  } // initializeLine

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̐V�K�s�}���������s�����\�b�h�ł��B
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void addRowLine() throws OAException
  {
    OARow maxRow = null;
    Number maxLineNumber = new Number(0);

    // ���o�Ɏ��і���:�o�^VO�擾
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();

    // �s�}��
    OARow row = (OARow)movementResultsLnVo.createRow();

    row.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
    row.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");

    // �����t���O1:�o�^���Z�b�g
    row.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_I); // �����t���O 1:�o�^
    movementResultsLnVo.last();
    movementResultsLnVo.next();
    movementResultsLnVo.insertRow(row);
    row.setNewRowState(Row.STATUS_INITIALIZED);

    movementResultsLnVo.first();
    while (movementResultsLnVo.getCurrentRow() != null)
    {
      OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

      movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
      movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");

      movementResultsLnVo.next();
    }

  } // addRowLine

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̌����������s�����\�b�h�ł��B
   * @param searchParams - �p�����[�^HashMap
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearchLine(
    HashMap searchParams
  ) throws OAException
  {
    // �p�����[�^�擾
    String searchHdrId = (String)searchParams.get(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);
    String productFlg  = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);

    // ���o�Ɏ��і���:�o�^VO�擾
    XxinvMovementResultsLnVOImpl movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // ����
    movementResultsLnVo.initQuery(
      searchHdrId,
      productFlg);
    // 1�s�߂��擾
    movementResultsLnVo.first();
    // ���o�Ɏ��уw�b�_VO�擾
    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // �f�[�^���擾�ł��Ȃ������ꍇ
    if (movementResultsLnVo.getRowCount() == 0)
    {
      // *********************** //
      // *  VO����������       * //
      // *********************** //
      OAViewObject vo = getXxinvMovementResultsLnVO1();
      vo.setWhereClauseParam(0,null);
      vo.setWhereClauseParam(1,null);
      vo.setWhereClauseParam(2,null);
      vo.setWhereClauseParam(3,null);
// 2008/08/21 v1.6 Y.Yamamoto Mod Start
//      vo.setWhereClauseParam(4, null);
//      vo.setWhereClauseParam(5, null);
      vo.setWhereClauseParam(4,null);
// 2008/08/21 v1.6 Y.Yamamoto Mod End
      vo.executeQuery();
      vo.insertRow(vo.createRow());
      // 1�s�ڂ��擾
      OARow row = (OARow)vo.first();
      // �L�[�ɒl���Z�b�g
      row.setNewRowState(Row.STATUS_INITIALIZED);
      row.setAttribute("MovHdrId", new Number(-1));

      // ************************ //
      // * �G���[���b�Z�[�W�o�� *
      // ************************ //
      throw new OAException(
        XxcmnConstants.APPL_XXCMN,
        XxcmnConstants.XXCMN10500, 
        null, 
        OAException.ERROR, 
        null);

    // �f�[�^���擾�ł����ꍇ
    } else
    {
      OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      
      // 1�s�ڂ��擾
      OARow resultsSearchRow = (OARow)resultsSearchVo.first();
      String actualFlg  = (String)resultsSearchRow.getAttribute("ActualFlg");

      // �w�b�_�ύX���Ȃ������ꍇ
      if ((XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                           makeHdrVORow.getAttribute("DbActualShipDate")))           // �o�ɓ�(����)�F�o�ɓ�(����)(DB)
             && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                                 makeHdrVORow.getAttribute("DbActualArrivalDate")))  // ����(����)�F����(����)(DB)
             && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                                 makeHdrVORow.getAttribute("DbOutPalletQty")))       // �p���b�g����(�o)�F�p���b�g����(�o)(DB)
             && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                                 makeHdrVORow.getAttribute("DbInPalletQty"))))       // �p���b�g����(��)�F�p���b�g����(��)(DB)
      {
        resultsSearchRow.setAttribute("ExeFlag", "1");
// 2008-06-26 H.Ito Mod Start
      // �w�b�_�ɕύX���������ꍇ�A�o�Ɏ��у��b�g��ʁA���Ɏ��у��b�g��ʑJ�ڕs�B
      } else
      {
        resultsSearchRow.setAttribute("ExeFlag", null);
      }
// 2008-06-26 H.Ito Mod End
      String exeFlg     = (String)resultsSearchRow.getAttribute("ExeFlag");

      // �L�[�ɒl���Z�b�g
      resultsSearchRow.setAttribute("HdrId", searchHdrId);

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();
        // �����t���O2:�X�V���Z�b�g
        movementResultsLnRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U);
        // �i�ڂ̓��͍��ڐ���
        movementResultsLnRow.setAttribute("ItemCodeReadOnly", Boolean.TRUE);
        
        // ���уf�[�^�敪��:1(�o�Ɏ���)�̏ꍇ
        if ("1".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");

        // ���уf�[�^�敪��:2(���Ɏ���)�̏ꍇ
        } else if ("2".equals(actualFlg))
        {
          movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");
          }
        }

        movementResultsLnVo.next();
      }
    }
  } // doSearchLine

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̓o�^�E�X�V���̃`�F�b�N���s���܂��B
   ***************************************************************************
   */
  public void checkLine()
// 2008-09-24 H.Itou Add Start
     throws OAException
// 2008-09-24 H.Itou Add End
  {
    // �i�ڊi�[�pHashMap����
    HashMap itemParams = new HashMap();
    // �ړ����я��VO�擾
    OAViewObject vo = getXxinvMovementResultsLnVO1();
    // 1�s�ڂ��擾
    vo.first();
    int i = 0;

    while (vo.getCurrentRow() != null)
    {
      OARow row = (OARow)vo.getCurrentRow();
      String itemCode = (String)row.getAttribute("ItemCode");
      
      // �i�ڎ擾
      String chkItem = (String)itemParams.get(itemCode);
      // �i�ڂ��擾�ł����ꍇ
      if (!XxcmnUtility.isBlankOrNull(chkItem))
      {
        // �G���[���b�Z�[�W�o��
        throw new OAException(
                    XxcmnConstants.APPL_XXINV,
                    XxinvConstants.XXINV10063);
      
      } else
      {
        itemParams.put(itemCode, itemCode);
        // �i�ڂ����͂���Ă����ꍇ
        if (!XxcmnUtility.isBlankOrNull(itemCode))
        {
          i++;
          row.setAttribute("LineNumber", new Number(i));
        }
      }
  
      vo.next();
    }
    // mod start ver1.3
    // �i�ږ����̓`�F�b�N
    if (i == 0)
    {
      // �g�[�N������
      MessageToken[] tokens = { new MessageToken(XxinvConstants.TOKEN_ITEM, XxinvConstants.TOKEN_NAME_ITEM) };
      // �G���[���b�Z�[�W�o��
      throw new OAException(
                  XxcmnConstants.APPL_XXINV,
                  XxinvConstants.XXINV10061,
                  tokens);
    }
    // mod end ver1.3
  } // checkLine

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̓o�^�E�X�V�������s�����\�b�h�ł��B
   * @return String ���^�[���R�[�h(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public String doExecute() throws OAException
  {
    boolean lineExeFlag = false;
    String retCode = XxcmnConstants.STRING_TRUE;
    String insFlag  = XxcmnConstants.STRING_N;
    
    // ���o�Ɏ��уw�b�_���擾
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow movHdrRow = (OARow)movementResultsHdVo.first();
    String processFlag = (String)movHdrRow.getAttribute("ProcessFlag");

    // ���o�Ɏ��і��׏��擾
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // 1�s�ڂ��擾
    movementResultsLnVo.first();

    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
    // 1�s�ڂ��擾
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    String productFlg  = (String)resultsSearchRow.getAttribute("ProductFlg");

    // �X�V�̏ꍇ
    if (XxinvConstants.PROCESS_FLAG_U.equals(processFlag))
    {
      // �ړ����׍X�V����
      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();
        
        // �V�K�o�^�̖��׍s�̏ꍇ
        if (XxinvConstants.PROCESS_FLAG_I.equals(movementResultsLnRow.getAttribute("ProcessFlag"))
              && (!XxcmnUtility.isBlankOrNull(movementResultsLnRow.getAttribute("ItemCode"))))
        {
          // �ړ��˗�/�w�����דo�^����
          insertMovLine(movHdrRow, movementResultsLnRow);
        }
        movementResultsLnVo.next();
      }

      // �ړ��w�b�_�X�V����(����(�X�V�L)�FMovHdrId�A����(�X�V��)�FTRUE�A�G���[�FFALSE)
      retCode = UpdateHdr();
      if (retCode.equals(XxcmnConstants.STRING_TRUE))
      {
        // �ړ��w�b�_ID���擾
        Number movHdrId = (Number)movHdrRow.getAttribute("MovHdrId");
        retCode = XxcmnUtility.stringValue(movHdrId);
      }
      resultsSearchRow.setAttribute("ExeFlag", "1");
    // �V�K�o�^�o�^�̏ꍇ
    } else
    {
      // �ړ��w�b�_ID���擾
      Number movHdrId = XxinvUtility.getMovHdrId(getOADBTransaction());
      movHdrRow.setAttribute("MovHdrId", movHdrId);
      // �ړ��ԍ����擾
      String movNum = XxcmnUtility.getSeqNo(getOADBTransaction(), "�ړ��ԍ�");

      movHdrRow.setAttribute("MovNum", movNum);
      movHdrRow.setAttribute("ProductFlg", productFlg);

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

        // �i�ڂ����͂���Ă����ꍇ
        if (!XxcmnUtility.isBlankOrNull(movementResultsLnRow.getAttribute("ItemCode")))
        {
          // �ړ��˗�/�w�����דo�^����
          insertMovLine(movHdrRow, movementResultsLnRow);
          lineExeFlag = true;
        }

        movementResultsLnVo.next();
      }
      // �ړ����ׂ��o�^����Ă����ꍇ
      if (lineExeFlag)
      {

        // �ړ��˗�/�w���w�b�_�o�^����
        insertMovHdr(movHdrRow);

        insFlag = XxcmnConstants.STRING_Y;
      }

      // �o�^����������ɏI�������ꍇ�A�ړ��w�b�_ID��߂�
      if (XxcmnConstants.STRING_Y.equals(insFlag))
      {
        retCode = XxcmnUtility.stringValue(movHdrId);
        resultsSearchRow.setAttribute("ExeFlag", "1");

      // �o�^�����I�������ꍇ�ASTRING_TRUE��߂�
      } else
      {
        retCode = XxcmnConstants.STRING_TRUE;
      }
    }
    return retCode;
  } // doExecute

  /*****************************************************************************
   * �ړ��˗�/�w���w�b�_(�A�h�I��)�Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void insertMovHdr(
    OARow hdrRow
  ) throws OAException
  {
    String apiName = "insertMovHdr";
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("BEGIN                                     ");
    sb.append("  INSERT INTO xxinv_mov_req_instr_headers(");
    sb.append("    mov_hdr_id                 "); // �ړ��w�b�_ID
    sb.append("   ,mov_num                    "); // �ړ��ԍ�
    sb.append("   ,mov_type                   "); // �ړ��^�C�v
    sb.append("   ,entered_date               "); // ���͓�
    sb.append("   ,instruction_post_code      "); // �w������
    sb.append("   ,status                     "); // �X�e�[�^�X
    sb.append("   ,notif_status               "); // �ʒm�X�e�[�^�X
    sb.append("   ,shipped_locat_id           "); // �o�Ɍ�ID
    sb.append("   ,shipped_locat_code         "); // �o�Ɍ��ۊǏꏊ
    sb.append("   ,ship_to_locat_id           "); // ���ɐ�ID
    sb.append("   ,ship_to_locat_code         "); // ���ɐ�ۊǏꏊ
    sb.append("   ,schedule_ship_date         "); // �o�ɗ\���
    sb.append("   ,schedule_arrival_date      "); // ���ɗ\���
    sb.append("   ,freight_charge_class       "); // �^���敪
    sb.append("   ,collected_pallet_qty       "); // �p���b�g�������
    sb.append("   ,out_pallet_qty             "); // �p���b�g����(�o)
    sb.append("   ,in_pallet_qty              "); // �p���b�g����(��)
    sb.append("   ,no_cont_freight_class      "); // �_��O�^���敪
    sb.append("   ,description                "); // �E�v
    sb.append("   ,organization_id            "); // �g�DID
    sb.append("   ,career_id                  "); // �^���Ǝ�ID
    sb.append("   ,freight_carrier_code       "); // �^���Ǝ�
    sb.append("   ,actual_career_id           "); // �^���Ǝ�ID_����
    sb.append("   ,actual_freight_carrier_code"); // �^���Ǝ�_����
    sb.append("   ,actual_shipping_method_code"); // �z���敪_����
    sb.append("   ,arrival_time_from          "); // ���׎���FROM
    sb.append("   ,arrival_time_to            "); // ���׎���TO
    sb.append("   ,weight_capacity_class      "); // �d�ʗe�ϋ敪
    sb.append("   ,actual_ship_date           "); // �o�Ɏ��ѓ�
    sb.append("   ,actual_arrival_date        "); // ���Ɏ��ѓ�
    sb.append("   ,item_class                 "); // ���i�敪
    sb.append("   ,product_flg                "); // ���i���ʋ敪
    sb.append("   ,no_instr_actual_class      "); // �w���Ȃ����ы敪
    sb.append("   ,comp_actual_flg            "); // ���ьv��ς݃t���O
    sb.append("   ,correct_actual_flg         "); // ���ђ����t���O
    sb.append("   ,screen_update_by           "); // ��ʍX�V��
    sb.append("   ,screen_update_date         "); // ��ʍX�V����
    sb.append("   ,created_by                 "); // �쐬��
    sb.append("   ,creation_date              "); // �쐬��
    sb.append("   ,last_updated_by            "); // �ŏI�X�V��
    sb.append("   ,last_update_date           "); // �ŏI�X�V��
    sb.append("   ,last_update_login)         "); // �ŏI�X�V���O�C��
    sb.append("  VALUES( ");
    sb.append("    :1 "                        ); // �ړ��w�b�_ID
    sb.append("   ,:2 "                        ); // �ړ��ԍ�
    sb.append("   ,:3 "                        ); // �ړ��^�C�v
    sb.append("   ,SYSDATE "                   ); // ���͓�
    sb.append("   ,:4 "                        ); // �w������
    sb.append("   ,'03' "                      ); // �X�e�[�^�X
    sb.append("   ,'40' "                      ); // �ʒm�X�e�[�^�X
    sb.append("   ,:5 "                        ); // �o�Ɍ�ID
    sb.append("   ,:6 "                        ); // �o�Ɍ��ۊǏꏊ
    sb.append("   ,:7 "                        ); // ���ɐ�ID
    sb.append("   ,:8 "                        ); // ���ɐ�ۊǏꏊ
    sb.append("   ,:9 "                        ); // �o�ɗ\���
    sb.append("   ,:10 "                       ); // ���ɗ\���
    sb.append("   ,:11 "                       ); // �^���敪
    sb.append("   ,:12 "                       ); // �p���b�g�������
    sb.append("   ,:13 "                       ); // �p���b�g����(�o)
    sb.append("   ,:14 "                       ); // �p���b�g����(��)
    sb.append("   ,:15 "                       ); // �_��O�^���敪
    sb.append("   ,:16 "                       ); // �E�v
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') "); // �g�DID
    sb.append("   ,:17 "                       ); // �^���Ǝ�ID
    sb.append("   ,:18 "                       ); // �^���Ǝ�
    sb.append("   ,:19 "                       ); // �^���Ǝ�ID_����
    sb.append("   ,:20 "                       ); // �^���Ǝ�_����
    sb.append("   ,:21 "                       ); // �z���敪_����
    sb.append("   ,:22 "                       ); // ���׎���FROM
    sb.append("   ,:23 "                       ); // ���׎���TO
    sb.append("   ,:24 "                       ); // �d�ʗe�ϋ敪
    sb.append("   ,:25 "                       ); // �o�Ɏ��ѓ�
    sb.append("   ,:26 "                       ); // ���Ɏ��ѓ�
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_ITEM_DIV_SECURITY') "); // ���i�敪
    sb.append("   ,:27 "                       ); // ���i���ʋ敪
    sb.append("   ,'Y' "                       ); // �w���Ȃ����ы敪
    sb.append("   ,'N' "                       ); // ���ьv��ς݃t���O
    sb.append("   ,'N' "                       ); // ���ђ����t���O
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // ��ʍX�V��
    sb.append("   ,SYSDATE "                   ); // ��ʍX�V����
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // �쐬��
    sb.append("   ,SYSDATE "                   ); // �쐬��
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // �ŏI�X�V��
    sb.append("   ,SYSDATE "                   ); // �ŏI�X�V��
    sb.append("   ,FND_GLOBAL.LOGIN_ID); "     ); // �ŏI�X�V���O�C��
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �����擾
      Number movHdrId                 = (Number)hdrRow.getAttribute("MovHdrId");                 // �ړ��w�b�_ID
      String movNum                   = (String)hdrRow.getAttribute("MovNum");                   // �ړ��ԍ�
      String movType                  = (String)hdrRow.getAttribute("MovType");                  // �ړ��^�C�v
      String instructionPostCode      = (String)hdrRow.getAttribute("InstructionPostCode");      // �w������
      Number shippedLocatId           = (Number)hdrRow.getAttribute("ShippedLocatId");           // �o�Ɍ�ID
      String description1             = (String)hdrRow.getAttribute("ShippedLocatCode");         // �o�Ɍ��ۊǏꏊ
      Number shipToLocatId            = (Number)hdrRow.getAttribute("ShipToLocatId");            // ���ɐ�ID
      String description2             = (String)hdrRow.getAttribute("ShipToLocatCode");          // ���ɐ�ۊǏꏊ
      Date   scheduleShipDate         = (Date)hdrRow.getAttribute("ScheduleShipDate");           // �o�ɗ\���
      Date   scheduleArrivalDate      = (Date)hdrRow.getAttribute("ScheduleArrivalDate");        // ���ɗ\���
      String freightChargeClass       = (String)hdrRow.getAttribute("FreightChargeClass");       // �^���敪
      Number collectedPalletQty       = (Number)hdrRow.getAttribute("CollectedPalletQty");       // �p���b�g�������
      Number outPalletQty             = (Number)hdrRow.getAttribute("OutPalletQty");             // �p���b�g����(�o)
      Number inPalletQty              = (Number)hdrRow.getAttribute("InPalletQty");              // �p���b�g����(��)
      String noContFreightClass       = (String)hdrRow.getAttribute("NoContFreightClass");       // �_��O�^���敪
      String description              = (String)hdrRow.getAttribute("Description");              // �E�v
      Number dctualCareerId           = (Number)hdrRow.getAttribute("ActualCareerId");           // �^���Ǝ�ID_����
      String actualFreightCarrierCode = (String)hdrRow.getAttribute("ActualFreightCarrierCode"); // �^���Ǝ�_����
      String actualShippingMethodCode = (String)hdrRow.getAttribute("ActualShippingMethodCode"); // �z���敪_����
      String arrivalTimeFrom          = (String)hdrRow.getAttribute("ArrivalTimeFrom");          // ���׎���FROM
      String arrivalTimeTo            = (String)hdrRow.getAttribute("ArrivalTimeTo");            // ���׎���TO
      String weightCapacityClass      = (String)hdrRow.getAttribute("WeightCapacityClass");      // �d�ʗe�ϋ敪
      Date   actualShipDate           = (Date)hdrRow.getAttribute("ActualShipDate");             // �o�Ɏ��ѓ�
      Date   actualArrivalDate        = (Date)hdrRow.getAttribute("ActualArrivalDate");          // ���Ɏ��ѓ�
      String productFlg               = (String)hdrRow.getAttribute("ProductFlg");               // ���i���ʋ敪

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));              // �ړ��w�b�_ID
      cstmt.setString(i++, movNum);                                    // �ړ��ԍ�
      cstmt.setString(i++, movType);                                   // �ړ��^�C�v
      cstmt.setString(i++, instructionPostCode);                       // �w������
      cstmt.setInt(i++, XxcmnUtility.intValue(shippedLocatId));        // �o�Ɍ�ID
      cstmt.setString(i++, description1);                              // �o�Ɍ��ۊǏꏊ
      cstmt.setInt(i++, XxcmnUtility.intValue(shipToLocatId));         // ���ɐ�ID
      cstmt.setString(i++, description2);                              // ���ɐ�ۊǏꏊ
      cstmt.setDate(i++, XxcmnUtility.dateValue(scheduleShipDate));    // �o�ɗ\���
      cstmt.setDate(i++, XxcmnUtility.dateValue(scheduleArrivalDate)); // ���ɗ\���
      cstmt.setString(i++, freightChargeClass);                        // �^���敪
      if (XxcmnUtility.isBlankOrNull(collectedPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // �p���b�g�������
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(collectedPalletQty));  // �p���b�g�������
      }
      if (XxcmnUtility.isBlankOrNull(outPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // �p���b�g����(�o)
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(outPalletQty));        // �p���b�g����(�o)
      }
      if (XxcmnUtility.isBlankOrNull(inPalletQty))
      {
        cstmt.setNull(i++, Types.INTEGER);                             // �p���b�g����(��)
      } else
      {
        cstmt.setInt(i++, XxcmnUtility.intValue(inPalletQty));         // �p���b�g����(��)
      }
      cstmt.setString(i++, noContFreightClass);                        // �_��O�^���敪
      cstmt.setString(i++, description);                               // �E�v
    // mod start ver1.5
      // �^���敪���F1(�L)�̏ꍇ
//      if (XxinvConstants.FREIGHT_CHARGE_CLASS_1.equals(freightChargeClass))
//      {
        cstmt.setInt(i++, XxcmnUtility.intValue(dctualCareerId));    // �^���Ǝ�ID
        cstmt.setString(i++, actualFreightCarrierCode);              // �^���Ǝ�
        cstmt.setInt(i++, XxcmnUtility.intValue(dctualCareerId));    // �^���Ǝ�ID_����
        cstmt.setString(i++, actualFreightCarrierCode);              // �^���Ǝ�_����
//      } else
//      {
//        cstmt.setNull(i++, Types.INTEGER);                           // �^���Ǝ�ID
//        cstmt.setNull(i++, Types.INTEGER);                           // �^���Ǝ�
//        cstmt.setNull(i++, Types.INTEGER);                           // �^���Ǝ�ID_����
//        cstmt.setNull(i++, Types.INTEGER);                           // �^���Ǝ�_����
//      }
    // mod end ver1.5
      cstmt.setString(i++, actualShippingMethodCode);                  // �z���敪_����
      cstmt.setString(i++, arrivalTimeFrom);                           // ���׎���FROM
      cstmt.setString(i++, arrivalTimeTo);                             // ���׎���TO
      cstmt.setString(i++, weightCapacityClass);                       // �d�ʗe�ϋ敪
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualShipDate));      // �o�Ɏ��ѓ�
      cstmt.setDate(i++, XxcmnUtility.dateValue(actualArrivalDate));   // ���Ɏ��ѓ�
      cstmt.setString(i++, productFlg);                                // ���i���ʋ敪

      //PL/SQL���s
      cstmt.execute();

      // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
      XxinvUtility.rollBack(getOADBTransaction());
      XxcmnUtility.writeLog(getOADBTransaction(),
                              XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxinvUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                                XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovHdr

  /*****************************************************************************
   * �ړ��˗�/�w������(�A�h�I��)�Ƀf�[�^��ǉ����܂��B
   * @param hdrRow - �w�b�_�s
   * @param linRow - ���׍s
   * @throws OAException - OA��O
   ****************************************************************************/
  public void insertMovLine(
    OARow hdrRow,
    OARow linRow
  ) throws OAException
  {
    String apiName = "insertMovLine";
    
    //PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE                        ");
    sb.append("  lt_mov_line_id xxinv_mov_req_instr_lines.mov_line_id%TYPE; ");
    sb.append("BEGIN                                     ");
    sb.append("  SELECT xxinv_mov_line_s1.NEXTVAL        ");
    sb.append("  INTO   lt_mov_line_id                   ");
    sb.append("  FROM   DUAL;                            ");
                // �ړ��˗�/�w������(�A�h�I��)�o�^
    sb.append("  INSERT INTO xxinv_mov_req_instr_lines(");
    sb.append("    mov_line_id                "); // �ړ�����ID
    sb.append("   ,mov_hdr_id                 "); // �ړ��w�b�_ID
    sb.append("   ,line_number                "); // ���הԍ�
    sb.append("   ,organization_id            "); // �g�DID
    sb.append("   ,item_id                    "); // OPM�i��ID
    sb.append("   ,item_code                  "); // �i��
    sb.append("   ,uom_code                   "); // �P��
    sb.append("   ,delete_flg                 "); // ����t���O
    sb.append("   ,created_by                 "); // �쐬��
    sb.append("   ,creation_date              "); // �쐬��
    sb.append("   ,last_updated_by            "); // �ŏI�X�V��
    sb.append("   ,last_update_date           "); // �ŏI�X�V��
    sb.append("   ,last_update_login)         "); // �ŏI�X�V���O�C��
    sb.append("  VALUES( ");
    sb.append("    lt_mov_line_id "            ); // �ړ�����ID
    sb.append("   ,:1 "                        ); // �ړ��w�b�_ID
    sb.append("   ,:2 "                        ); // ���הԍ�
    sb.append("   ,FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID') "); // �g�DID
    sb.append("   ,:3 "                        ); // OPM�i��ID
    sb.append("   ,:4 "                        ); // �i��
    sb.append("   ,:5 "                        ); // �P��
    sb.append("   ,'N' "                       ); // ����t���O
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // �쐬��
    sb.append("   ,SYSDATE "                   ); // �쐬��
    sb.append("   ,FND_GLOBAL.USER_ID "        ); // �ŏI�X�V��
    sb.append("   ,SYSDATE "                   ); // �ŏI�X�V��
    sb.append("   ,FND_GLOBAL.LOGIN_ID); "     ); // �ŏI�X�V���O�C��
    sb.append("END; ");
    
    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {
      // �����擾
      Number movHdrId   = (Number)hdrRow.getAttribute("MovHdrId");    // �ړ��w�b�_ID
      Number lineNumber = (Number)linRow.getAttribute("LineNumber");  // ���הԍ�
      Number itemId     = (Number)linRow.getAttribute("ItemId");      // OPM�i��ID
      String itemCode   = (String)linRow.getAttribute("ItemCode");    // �i��
      String uomCode    = (String)linRow.getAttribute("UomCode");     // �P��

      int i = 1;
      // �p�����[�^�ݒ�(IN�p�����[�^)
      cstmt.setInt(i++, XxcmnUtility.intValue(movHdrId));   // �ړ��w�b�_ID
      cstmt.setInt(i++, XxcmnUtility.intValue(lineNumber)); // ���הԍ�
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));     // OPM�i��ID
      cstmt.setString(i++, itemCode);                       // �i��
      cstmt.setString(i++, uomCode);                        // �P��

      //PL/SQL���s
      cstmt.execute();

      // PL/SQL���s����O�̏ꍇ
    } catch(SQLException s)
    {
      // ���[���o�b�N
    XxinvUtility.rollBack(getOADBTransaction());
    XxcmnUtility.writeLog(getOADBTransaction(),
                            XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
    throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);

    } finally
    {
      try
      {
        //�������ɃG���[�����������ꍇ��z�肷��
        cstmt.close();
      } catch(SQLException s)
      {
        // ���[���o�b�N
        XxinvUtility.rollBack(getOADBTransaction());
        XxcmnUtility.writeLog(getOADBTransaction(),
                                XxinvConstants.CLASS_AM_XXINV510001J + XxcmnConstants.DOT + apiName,
                                s.toString(),
                                6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                                XxcmnConstants.XXCMN10123);
      }
    }
  } // insertMovLine

  /***************************************************************************
   * �ړ��w�b�_ID�擾�������s�����\�b�h�ł��B
   * @return Number �ړ��w�b�_ID
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public Number getHdrId() throws OAException
  {
    
    // ���o�Ɏ��уw�b�_���擾
    OAViewObject movementResultsHdVo = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow movHdrRow = (OARow)movementResultsHdVo.first();
    Number movHdrId = (Number)movHdrRow.getAttribute("MovHdrId");


    return movHdrId;
  } // getHdrId

  /***************************************************************************
   * �R�~�b�g�������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doCommit() throws OAException
  {
    // �R�~�b�g
    getOADBTransaction().commit();
// 2008/08/22 v1.6 Y.Yamamoto Mod Start
    // �ύX�Ɋւ���x�����N���A
    super.clearWarnAboutChanges();  
// 2008/08/22 v1.6 Y.Yamamoto Mod End
  } // doCommit

  /***************************************************************************
   * ���[���o�b�N�������s�����\�b�h�ł��B
   ***************************************************************************
   */
  public void doRollBack()
  {
    // ���[���o�b�N
    XxcmnUtility.rollBack(getOADBTransaction());
  }

// 2008/08/20 v1.6 Y.Yamamoto Mod Start
  /***************************************************************************
   * �ύX�Ɋւ���x�����Z�b�g���܂��B
   ***************************************************************************
   */
  public void doWarnAboutChanges()
  {
    // �ړ����я��w�b�_VO�擾
    OAViewObject hdrVo = getXxinvMovementResultsHdVO1();
    OARow hdrRow  = (OARow)hdrVo.first();

    // ���Âꂩ�̍��ڂɕύX���������ꍇ
    if (!XxcmnUtility.isEquals(hdrRow.getAttribute("ActualShipDate"),     hdrRow.getAttribute("DbActualShipDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("ActualArrivalDate"),  hdrRow.getAttribute("DbActualArrivalDate"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("CollectedPalletQty"), hdrRow.getAttribute("DbCollectedPalletQty"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("OutPalletQty"),       hdrRow.getAttribute("DbOutPalletQty"))
     || !XxcmnUtility.isEquals(hdrRow.getAttribute("InPalletQty"),        hdrRow.getAttribute("DbInPalletQty"))) 
    {
      // �ύX�Ɋւ���x����ݒ�
      super.setWarnAboutChanges();  
    }
  } // doWarnAboutChanges

  /***************************************************************************
   * ���o�Ɏ��і��׉�ʂ̃��b�g���уA�C�R���̐؂�ւ����s�����\�b�h�ł��B
   * @param searchParams - �p�����[�^HashMap
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doLotSwitcher(
    HashMap searchParams
  ) throws OAException
  {
    // �p�����[�^�擾
    String searchHdrId = (String)searchParams.get(XxinvConstants.URL_PARAM_SEARCH_MOV_ID);
    String productFlg  = (String)searchParams.get(XxinvConstants.URL_PARAM_PRODUCT_FLAG);

    String addRowOn    = "0";

    // ���o�Ɏ��уw�b�_VO�擾
    OAViewObject makeHdrVO = getXxinvMovementResultsHdVO1();
    // 1�s�ڂ��擾
    OARow makeHdrVORow = (OARow)makeHdrVO.first();

    // ���o�Ɏ��і���:VO�擾
    OAViewObject movementResultsLnVo = getXxinvMovementResultsLnVO1();
    // 1�s�ڂ��擾
    movementResultsLnVo.first();

    OAViewObject resultsSearchVo = getXxinvMovResultsSearchVO1();
      
    // 1�s�ڂ��擾
    OARow resultsSearchRow = (OARow)resultsSearchVo.first();
    String actualFlg  = (String)resultsSearchRow.getAttribute("ActualFlg");

    // �w�b�_�ύX���Ȃ������ꍇ
    if ((XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualShipDate"),
                         makeHdrVORow.getAttribute("DbActualShipDate")))           // �o�ɓ�(����)�F�o�ɓ�(����)(DB)
           && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("ActualArrivalDate"),
                               makeHdrVORow.getAttribute("DbActualArrivalDate")))  // ����(����)�F����(����)(DB)
           && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("OutPalletQty"),
                               makeHdrVORow.getAttribute("DbOutPalletQty")))       // �p���b�g����(�o)�F�p���b�g����(�o)(DB)
           && (XxcmnUtility.isEquals(makeHdrVORow.getAttribute("InPalletQty"),
                               makeHdrVORow.getAttribute("DbInPalletQty"))))       // �p���b�g����(��)�F�p���b�g����(��)(DB)
    {
      resultsSearchRow.setAttribute("ExeFlag", "1");
    // �w�b�_�ɕύX���������ꍇ�A�o�Ɏ��у��b�g��ʁA���Ɏ��у��b�g��ʑJ�ڕs�B
    } else
    {
      resultsSearchRow.setAttribute("ExeFlag", null);
    }
    String exeFlg     = (String)resultsSearchRow.getAttribute("ExeFlag");

    // �L�[�ɒl���Z�b�g
    resultsSearchRow.setAttribute("HdrId", searchHdrId);

    while (movementResultsLnVo.getCurrentRow() != null)
    {
      OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

      if (XxcmnUtility.isEquals(movementResultsLnRow.getAttribute("ItemCodeReadOnly"),Boolean.TRUE))
      {
        // �����t���O2:�X�V���Z�b�g
        movementResultsLnRow.setAttribute("ProcessFlag", XxinvConstants.PROCESS_FLAG_U);
        // �i�ڂ̓��͍��ڐ���
        movementResultsLnRow.setAttribute("ItemCodeReadOnly", Boolean.TRUE);
        
        // ���уf�[�^�敪��:1(�o�Ɏ���)�̏ꍇ
        if ("1".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");

        // ���уf�[�^�敪��:2(���Ɏ���)�̏ꍇ
        } else if ("2".equals(actualFlg))
        {
          if ("1".equals(exeFlg))
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetails");
          } else
          {
            movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");
          }
          movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
        }
        addRowOn = "0";
      } else
      {
        addRowOn = "1";
      }
      movementResultsLnVo.next();
    }

    if ("1".equals(addRowOn)) 
    {
      movementResultsLnVo.first();

      while (movementResultsLnVo.getCurrentRow() != null)
      {
        OARow movementResultsLnRow = (OARow)movementResultsLnVo.getCurrentRow();

        movementResultsLnRow.setAttribute("ShippedLotSwitcher", "ShippedLotDetailsDisable");
        movementResultsLnRow.setAttribute("ShipToLotSwitcher", "ShipToLotDetailsDisable");

        movementResultsLnVo.next();
      }
    }
  } // doLotSwitcher
// 2008/08/20 v1.6 Y.Yamamoto Mod End

  /**
   * 
   * Container's getter for XxinvMovementResultsVO1
   */
  public XxinvMovementResultsVOImpl getXxinvMovementResultsVO1()
  {
    return (XxinvMovementResultsVOImpl)findViewObject("XxinvMovementResultsVO1");
  }


  /**
   * 
   * Container's getter for XxinvMovementResultsHdPVO1
   */
  public XxinvMovementResultsHdPVOImpl getXxinvMovementResultsHdPVO1()
  {
    return (XxinvMovementResultsHdPVOImpl)findViewObject("XxinvMovementResultsHdPVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsHdVO1
   */
  public XxinvMovementResultsHdVOImpl getXxinvMovementResultsHdVO1()
  {
    return (XxinvMovementResultsHdVOImpl)findViewObject("XxinvMovementResultsHdVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovementResultsLnVO1
   */
  public XxinvMovementResultsLnVOImpl getXxinvMovementResultsLnVO1()
  {
    return (XxinvMovementResultsLnVOImpl)findViewObject("XxinvMovementResultsLnVO1");
  }

  /**
   * 
   * Container's getter for XxinvMovResultsHdSearchVO1
   */
  public XxinvMovResultsHdSearchVOImpl getXxinvMovResultsHdSearchVO1()
  {
    return (XxinvMovResultsHdSearchVOImpl)findViewObject("XxinvMovResultsHdSearchVO1");
  }





}
