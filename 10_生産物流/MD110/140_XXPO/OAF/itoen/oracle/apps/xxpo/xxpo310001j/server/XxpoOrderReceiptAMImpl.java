/*============================================================================
* �t�@�C���� : XxpoOrderReceiptAMImpl
* �T�v����   : ������э쐬:������э쐬�A�v���P�[�V�������W���[��
* �o�[�W���� : 1.2
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-04 1.0  �g������     �V�K�쐬
* 2008-05-23 1.1  �g������     �����ۑ�#42�A�����s����O#1,2��Ή�
* 2008-06-11 1.2  �g������     ST�s����O#72��Ή�
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;

import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.ArrayList;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.apps.fnd.framework.OAAttrValException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.OARow;
import oracle.apps.fnd.framework.OAViewObject;

import oracle.apps.fnd.common.MessageToken;

import oracle.jbo.Row;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

import itoen.oracle.apps.xxcmn.util.server.XxcmnOAApplicationModuleImpl;
import itoen.oracle.apps.xxcmn.util.XxcmnConstants;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;
import itoen.oracle.apps.xxpo.util.XxpoUtility;

/***************************************************************************
 * ������э쐬:������э쐬�A�v���P�[�V�������W���[���ł��B
 * @author  SCS �g�� ����
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderReceiptAMImpl extends XxcmnOAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderReceiptAMImpl()
  {
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxpo.xxpo310001j.server", "XxpoOrderReceiptAMLocal");
  }

  /***************************************************************************
   * (��������������)�������������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void initialize() throws OAException
  {
    // ***************************** //
    // * �������:����VO ��s�擾  * //
    // ***************************** //
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!orderReceiptSerchVO.isPreparedForExecution())
    {
      orderReceiptSerchVO.setMaxFetchSize(0);
      orderReceiptSerchVO.insertRow(orderReceiptSerchVO.createRow());
      // 1�s�ڂ��擾
      OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();
      // �L�[�ɒl���Z�b�g
      orderReceiptSerchVORow.setNewRowState(Row.STATUS_INITIALIZED);
      orderReceiptSerchVORow.setAttribute("RowKey", new Number(1));
    }
       
    // ************************************ //
    // * �[����ݒ菈��(�O�����[�U�̂�)   * //
    // ************************************ //
    setLocationCode();
    
  } // initialize

  /***************************************************************************
   * (��������������)�[�����ݒ肷�郁�\�b�h�ł��B(�O�����[�U�̂�)
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void setLocationCode() throws OAException
  {

/*
    // *************************** //
    // * ���[�U�[���擾        * //
    // *************************** //
    getUserData();
*/
    // �����������VO�擾
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1�s�ڂ��擾
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();

// 20080528 add yoshimoto Start
    // *************************** //
    // * ���[�U�[���擾        * //
    // *************************** //
    getUserData(orderReceiptSerchVORow);
// 20080528 add yoshimoto End

    // �]�ƈ��敪���擾
    String peopleCode = (String)orderReceiptSerchVORow.getAttribute("PeopleCode"); // �]�ƈ��敪

    // �]�ƈ��敪��2:�O���̏ꍇ
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {

      // �O�����[�U�̎��q�ɂ̃J�E���g���擾
      int warehouseCount = getWarehouseCount();

      // ���q�ɂ̃J�E���g��1�̏ꍇ
      if (warehouseCount == 1) 
      {
        // *********************** //
        // * ���q�ɏ����擾    * //
        // *********************** //
        HashMap retHashMap = getWarehouse();

        // ���������̔[����֎��q�ɂ��Œ�l�Ƃ��Đݒ�
        orderReceiptSerchVORow.setAttribute("LocationCode", retHashMap.get("LocationCode")); // �ۊǑq�ɃR�[�h
        orderReceiptSerchVORow.setAttribute("LocationName", retHashMap.get("LocationName")); // �ۊǑq�ɖ�
        orderReceiptSerchVORow.setAttribute("LocationCodeReadOnly", Boolean.TRUE);           // �ۊǑq��(�ǎ��p�֕ύX)
      }
    }
  } // setLocationCode

  /***************************************************************************
   * (��������������)���q�ɂ̃J�E���g���擾���郁�\�b�h�ł��B
   * @return int ���q�ɂ̃J�E���g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public int getWarehouseCount() throws OAException
  {
    // ���q�ɂ̃J�E���g���擾 
    int warehouseCount = XxpoUtility.getWarehouseCount(
                           getOADBTransaction());  // �g�����U�N�V����

    return warehouseCount;
  } // getWarehouseCount

  /***************************************************************************
   * (��������������)���q�ɂ��擾���郁�\�b�h�ł��B
   * @return HashMap ���q�ɏ��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap getWarehouse() throws OAException
  {
    // ���q�ɏ��擾 
    HashMap retHashMap = XxpoUtility.getWarehouse(
                           getOADBTransaction());  // �g�����U�N�V����

    return retHashMap;
  } // getWarehouse

  /***************************************************************************
   * (��������������)�����{�^���������̕K�{�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doRequiredCheck() throws OAException
  {

    // �������:��������VO�擾
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();
    // 1�s�ڂ��擾
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();

    // �[����(From)���擾
    Object fdDate  = orderReceiptSerchVORow.getAttribute("DeliveryDateFrom");
    // �[����R�[�h���擾
    Object locationCode  = orderReceiptSerchVORow.getAttribute("LocationCode");

    ArrayList exceptions = new ArrayList(100);

    // �[����(From)���ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(fdDate))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            orderReceiptSerchVO.getName(),
                            orderReceiptSerchVORow.getKey(),
                            "DeliveryDateFrom",
                            fdDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10002));
    }

    // �[���悪�ݒ肳��Ă��Ȃ��ꍇ
    if (XxcmnUtility.isBlankOrNull(locationCode))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            orderReceiptSerchVO.getName(),
                            orderReceiptSerchVORow.getKey(),
                            "LocationCode",
                            locationCode,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10002));
    }

    OAException.raiseBundledOAException(exceptions);

  } // doRequiredCheck

  /***************************************************************************
   * (��������������)�����������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doSearch(
    HashMap searchParams
  ) throws OAException
  {

    // �O�����[�U���ʃt���O�擾
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();
    orderReceiptSerchVO.first();
    String peopleCode = (String)orderReceiptSerchVO.getCurrentRow().getAttribute("PeopleCode");
    searchParams.put("PeopleCode", peopleCode);

    // �]�ƈ��敪��2:�O���̏ꍇ�A�����ID��ݒ�
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      searchParams.put("location", orderReceiptSerchVO.getCurrentRow().getAttribute("LocationCode"));
    }

    // ����������VO�擾
    XxpoOrderReceiptVOImpl orderReceiptVO = getXxpoOrderReceiptVO1();

    // ����
    orderReceiptVO.initQuery(searchParams);  // �����p�����[�^�pHashMap

    // 1�s�ڂ��擾
    OARow row = (OARow)orderReceiptVO.first();
  } // doSearch

  /***************************************************************************
   * (��������������)�y�[�W���O�̍ۂɃ`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void checkBoxOff() throws OAException
  {
    // �������VO�擾
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);
    
    // �I���`�F�b�N�{�b�N�X��OFF�ɂ��܂��B
    if ((rows != null) || (rows.length != 0))
    {
      OARow row = null;
      for (int i = 0; i < rows.length; i++)
      {
        // i�Ԗڂ̍s���擾
        row = (OARow)rows[i];
        row.setAttribute("Selection", XxcmnConstants.STRING_N);
      }
    }
  } // checkBoxOff

  /***************************************************************************
   * (��������������)�����Ώۍs�I���`�F�b�N���s���܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkSelect() throws OAException
  {
    // �������VO�擾
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    // *************************************************** //
    // * ����1:�I���`�F�b�N�{�b�N�X���I���`�F�b�N        * //
    // *************************************************** //
    if ((rows == null) || (rows.length == 0))
    {

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXPO,
                  XxpoConstants.XXPO30040,
                  null,
                  OAException.ERROR,
                  null);
    }
  }

  /***************************************************************************
   * (��������������)�ꊇ����������s���܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doBatchReceipt() throws OAException
  {

    ArrayList exceptions = new ArrayList(100);

    // �������VO�擾
    OAViewObject vo = getXxpoOrderReceiptVO1();
    Row[] rows = vo.getFilteredRows("Selection", XxcmnConstants.STRING_Y);

    for (int i = 0; i < rows.length; i++)
    {

      OARow row = (OARow)rows[i];

      boolean retFlag;

      // *************************************************** //
      // * ����2:����ԕi����(�A�h�I��)�ɓo�^�ς݃`�F�b�N  * //
      // * ����3:OPM�݌ɉ�vCLOSE�`�F�b�N                  * //
      // * ����4:�������`�F�b�N                            * //
      // *************************************************** //
      retFlag = chkBatchReceipt(exceptions,
                                vo,
                                row);

      // �`�F�b�N�ŃG���[�����������ꍇ�A�㑱�����̓X�L�b�v
      if (retFlag)
      {
        continue;
      }

      // *************************************************** //
      // * ����5:�d�����э쐬����(�R���J�����g)            * //
      // *************************************************** //
      doStockResultMake(exceptions,
                        vo,
                        row);
      
    }

    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      doRollBack();
      OAException.raiseBundledOAException(exceptions);

    // ��O���������Ă��Ȃ��ꍇ�́A�R�~�b�g����
    } else 
    {

      doCommit();

      // �X�V�������b�Z�[�W
      throw new OAException(
        XxcmnConstants.APPL_XXPO,
        XxpoConstants.XXPO30050,
        null,
        OAException.INFORMATION,
        null);
    }

  } // doBatchReceipt

  /***************************************************************************
   * (��������������)�ꊇ��������̎��O�`�F�b�N���s���܂��B
   * @param exceptions �G���[���X�g
   * @param vo ��������VO
   * @param row �����Ώ۔����f�[�^
   * @return boolean �G���[����:true�A�G���[����:false
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean chkBatchReceipt(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    boolean retFlag;

    // *************************************************** //
    // * ����2:����ԕi����(�A�h�I��)�ɓo�^�ς݃`�F�b�N  * //
    // *************************************************** //
    String headerNumber = (String)row.getAttribute("HeaderNumber"); // �����ԍ�

    // ���э쐬�ς݃`�F�b�N
    String chkFlag = XxpoUtility.chkRcvAndRtnTxnsInput(
                       getOADBTransaction(),
                       headerNumber);

    // �`�F�b�N�ŃG���[�����������ꍇ
    if (XxcmnConstants.STRING_Y.equals(chkFlag))
    {

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10203,
                            null));

      // �G���[����
      return true;
    }

    // *************************************************** //
    // * ����3:OPM�݌ɉ�vCLOSE�`�F�b�N                  * //
    // *************************************************** //
    Date deliveryDate = (Date)row.getAttribute("DeliveryDate");
    retFlag = XxpoUtility.chkStockClose(
                            getOADBTransaction(),
                            deliveryDate);

    // CLOSE�̏ꍇ
    if (retFlag)
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10205,
                            null));
                            
      // �G���[����
      return true;
    }

    // ************************************************** //
    // * ����4:�������`�F�b�N                           * //
    // ************************************************** //
    // �V�X�e�����t���擾
    Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());

    // �[���\������������łȂ����m�F
    retFlag = XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate);

    // �`�F�b�N�ŃG���[�����������ꍇ
    if (retFlag)
    {
      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "DeliveryDate",
                            deliveryDate,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10204,
                            null));

      // �G���[����
      return true;
    }

    // �G���[����
    return false;
  } // chkBatchReceipt

  /***************************************************************************
   * (��������������)�R���J�����g�F�d�����э쐬�����ł��B
   * @param exceptions �G���[���X�g
   * @param vo ��������VO
   * @param row �����Ώ۔�������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doStockResultMake(
    ArrayList exceptions,
    OAViewObject vo,
    OARow row
  ) throws OAException
  {

    String headerNumber = (String)row.getAttribute("HeaderNumber"); // �����ԍ�

    // �R���J�����g�F�d�����э쐬�����N��
    String retFlag = XxpoUtility.doStockResultMake(
                                   getOADBTransaction(), // �g�����U�N�V����
                                   headerNumber);        // �����ԍ�

    // ����I���̏ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
    {
      //�g�[�N������
      MessageToken[] tokens = { new MessageToken(XxpoConstants.TOKEN_PROCESS,
                                                 XxpoConstants.TOKEN_NAME_STOCK_RESULT_MAKE) };
      throw new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN05002,
                            tokens);

    }
  } // doStockResultMake

  /***************************************************************************
   * (��������ڍ׉��)�������������s�����\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void initialize2(
    HashMap params
  ) throws OAException
  {

    // ***************************** //
    // * �p�����[�^�̎擾          * //
    // ***************************** //
    String startCondition = (String)params.get("StartCondition");
    String headerNumber   = (String)params.get("HeaderNumber");

    // ******************************************* //
    // * ��������ڍ�:��������ڍ�PVO�擾        * //
    // ******************************************* //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!orderReceiptDetailsPVO.isPreparedForExecution())
    {
      // 1�s���Ȃ��ꍇ�A��s�쐬
      orderReceiptDetailsPVO.setMaxFetchSize(0);
      orderReceiptDetailsPVO.executeQuery();
      orderReceiptDetailsPVO.insertRow(orderReceiptDetailsPVO.createRow());
    }

    // 1�s�ڂ��擾
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();
    String chkHeaderNumber = (String)orderReceiptDetailsPVORow.getAttribute("HeaderNumber");

    // �L�[�l���Z�b�g
    orderReceiptDetailsPVORow.setAttribute("RowKey", new Number(1));
    // �N���������Z�b�g
    orderReceiptDetailsPVORow.setAttribute("pStartCondition", startCondition);
    // �����ԍ����Z�b�g
    orderReceiptDetailsPVORow.setAttribute("pHeaderNumber",   headerNumber);

// 20080528 add yoshimoto Start
    // *************************** //
    // * ���[�U�[���擾        * //
    // *************************** //
    getUserData(orderReceiptDetailsPVORow);
// 20080528 add yoshimoto End

    // *********************************************** //
    // * �N�������� "1"(���j���[����N��)�̏ꍇ      * //
    // *********************************************** //
    if (XxpoConstants.START_CONDITION_1.equals(startCondition))
    {

      // ************************ //
      // * ���ڐ���             * //
      // ************************ //
      // �K�p�{�^����ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
      // �w�b�_.�E�v��ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
      // �����{�^���������_�����O�ς݂֕ύX
      orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.TRUE);
      // �����{�^���������_�����O�ς݂֕ύX
      orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.TRUE);

      // ���������肳��Ă���ꍇ
      if (!"-1".equals(headerNumber))
      {

        // ************************************** //
        // * ��������ڍ�:�����w�b�_VO ��s�擾 * //
        // ************************************** //
        XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();
        OARow orderHeaderVORow = null;

        // �������{
        orderHeaderVO.initQuery(params);

        // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
        if (orderHeaderVO.getRowCount() == 0)
        {
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

          // ************************ //
          // * �G���[���b�Z�[�W�o�� * //
          // ************************ //
          throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
        }

        // ***************************************** //
        // * ��������ڍ�:�o�^�w�b�_VO ���͐���    * //
        // ***************************************** //
        orderHeaderVORow = (OARow)orderHeaderVO.first();
        String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

        // �X�e�[�^�X��"���z�m���"(35)�̏ꍇ
        if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
        {
          // �w�b�_.�E�v��ReadOnly������
          orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
        } else 
        {
          // �w�b�_.�E�v��ReadOnly������
          orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
        }

        // ************************************** //
        // * ��������ڍ�:��������VO ��s�擾   * //
        // ************************************** //
        XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
        OARow orderDetailsTabVOow = null;

        // �������{
        orderDetailsTabVO.initQuery(headerNumber);

        // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
        if (orderDetailsTabVO.getRowCount() == 0)
        {
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

          // ************************ //
          // * �G���[���b�Z�[�W�o�� * //
          // ************************ //
          throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
        }

        // ************************ //
        // * ���ڐ���             * //
        // ************************ //
        // �K�p�{�^����ReadOnly������
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);
        // ����No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // �x��No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // �����{�^����ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      } else 
      {
        if (!XxcmnUtility.isBlankOrNull(chkHeaderNumber))
        {
          // �K�p�{�^����ReadOnly������
          orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);          
        }
      }

    // *********************************************** //
    // * �N�������� "2"(���������������N��)�̏ꍇ  * //
    // *********************************************** //
    } else 
    {

      // ************************************** //
      // * ��������ڍ�:�����w�b�_VO ��s�擾 * //
      // ************************************** //
      XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();
      OARow orderHeaderVORow = null;

      // �������{
      orderHeaderVO.initQuery(params);
   
      // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
      if (orderHeaderVO.getRowCount() == 0)
      {

        // ����No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // �x��No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // �����{�^����񃌃��_�����O�֕ύX
        orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
        // �����{�^����񃌃��_�����O�֕ύX
        orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);
        // �E�v�{�^����ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
        // �w�b�_.�E�v��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",   Boolean.TRUE);

        // ************************ //
        // * �G���[���b�Z�[�W�o�� * //
        // ************************ //
        throw new OAException(
                    XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10500,
                    null,
                    OAException.ERROR,
                    null);
      }

      // ***************************************** //
      // * ��������ڍ�:�o�^�w�b�_VO ���͐���    * //
      // ***************************************** //
      orderHeaderVORow = (OARow)orderHeaderVO.first();
      String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

      // �X�e�[�^�X��"���z�m���"(35)�̏ꍇ
      if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
      {
        // �w�b�_.�E�v��ReadOnly������
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
      } else
      {
        // �w�b�_.�E�v��ReadOnly������
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
      }

      orderReceiptDetailsPVORow.setAttribute("HeaderNumber", (String)orderHeaderVO.first().getAttribute("HeaderNumber"));
      orderReceiptDetailsPVORow.setAttribute("RequestNumber", (String)orderHeaderVO.first().getAttribute("RequestNumber"));

      // ************************************** //
      // * ��������ڍ�:��������VO ��s�擾   * //
      // ************************************** //
      XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
      OARow orderDetailsTabVOow = null;

      // �������{
      orderDetailsTabVO.initQuery(headerNumber);

      // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
      if (orderDetailsTabVO.getRowCount() == 0)
      {

        // ����No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
        // �x��No��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
        // �����{�^����񃌃��_�����O�֕ύX
        orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
        // �����{�^����񃌃��_�����O�֕ύX
        orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);
        // �E�v�{�^����ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.TRUE);
        // �w�b�_.�E�v��ReadOnly�֕ύX
        orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",   Boolean.TRUE);

        // ************************ //
        // * �G���[���b�Z�[�W�o�� * //
        // ************************ //
        throw new OAException(
                      XxcmnConstants.APPL_XXCMN,
                      XxcmnConstants.XXCMN10500,
                      null,
                      OAException.ERROR,
                      null);
      }

      // ************************ //
      // * ���ڐ���             * //
      // ************************ //
      // �K�p�{�^����ReadOnly������
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly",         Boolean.FALSE);
      // ����No��ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
      // �x��No��ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
      // �����{�^����񃌃��_�����O�֕ύX
      orderReceiptDetailsPVORow.setAttribute("SearchRendered",  Boolean.FALSE);
      // �����{�^����񃌃��_�����O�֕ύX
      orderReceiptDetailsPVORow.setAttribute("DeleteRendered",  Boolean.FALSE);

    }

    // ************************************************* //
    // * ��������ڍ�:���v�Z�oVO �����\���s�擾        * //
    // ************************************************* //
    XxpoOrderDetailTotalVOImpl orderDetailTotalVO = getXxpoOrderDetailTotalVO1();
 
    // �������{
    // 1�s���Ȃ��ꍇ
    if (!"-1".equals(headerNumber)) {
      orderDetailTotalVO.initQuery(headerNumber);
      orderDetailTotalVO.first();
    }

    // ***************************************** //
    // * ��������ڍ�:��������VO ���͐���      * //
    // ***************************************** //
    // ���������肳��Ă���ꍇ
    if (!"-1".equals(headerNumber))
    {
      XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
      if (orderDetailsTabVO.getRowCount() > 0)
      {

        // �������ׂ̓��͐�������{
        readOnlyChangedDetailsTab();

      }
    }
  } // initialize2

  /***************************************************************************
   * (��������ڍ׉��)���͐���(��������)���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void readOnlyChangedDetailsTab() throws OAException
  {

    // ��������ڍ�:��������VO�擾
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    // ���ݍs���擾�ł���ԁA�������J��Ԃ�
    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // ����.���z�m��t���O���擾
      String moneyDecisionFlag = (String)orderDetailsTabVORow.getAttribute("MoneyDecisionFlag");
      // ����.�����Ǘ��敪���擾
      String costManageCode = (String)orderDetailsTabVORow.getAttribute("CostManageCode");

      // ***************************************** //
      // * ���z�m��t���O�ɂ�鐻�������ڐ���    * //
      // ***************************************** //
      // ���׋��z�m��t���O��"���z�m���"(Y)�̏ꍇ
      if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
      {

        // �������ׂ̐�������ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("ProductionDateReadOnly",  Boolean.TRUE);
        // �������ׂ̓�����ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("ItemAmountReadOnly",      Boolean.TRUE);
        // �������ׂ̑S���ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("AllReceiptReadOnly",      Boolean.TRUE);
        // �������ׂ̓E�v��ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("OrderDetailDescReadOnly", Boolean.TRUE);

      // �i�ڂ̌����Ǘ��敪������(0)�ȊO�̏ꍇ
      } else if (!XxpoConstants.COST_MANAGE_CODE_R.equals(costManageCode))
      {

        // �������ׂ̐�������ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("ProductionDateReadOnly", Boolean.TRUE);

      }

      // ************************************ //
      // * ���Z�L���`�F�b�N                 * //
      // ************************************ //
      boolean conversionFlag = false;
      String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
      String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
      String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

      // ���Z�L���`�F�b�N�����{
      conversionFlag = chkConversion(
                         prodClassCode,  // ���i�敪
                         itemClassCode,  // �i�ڋ敪
                         convUnit);      // ���o�Ɋ��Z�P��

      // *********************************** //
      // *  �������ڐ���                   * //
      // *********************************** //
      if (conversionFlag)
      {
        // �������ׂ̓�����ǎ��p�ɕύX
        orderDetailsTabVORow.setAttribute("ItemAmountReadOnly", Boolean.TRUE);
      }

      orderDetailsTabVO.next();
    }
  } // readOnlyChangedReceiptDetails2

  /***************************************************************************
   * (��������ڍ׉��)�����{�^���������̕K�{�`�F�b�N���s�����\�b�h�ł��B
   * @param params �`�F�b�N����
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doRequiredCheck2(
    HashMap params
  ) throws OAException
  {

    // ��������ڍ�PVO���擾
    OAViewObject vo = getXxpoOrderReceiptDetailsPVO1();
    OARow row = (OARow)vo.first();

    // ����No���擾
    Object headerNumber  = params.get("HeaderNumber");
    // �x��No���擾
    Object requestNumber = params.get("RequestNumber");

    ArrayList exceptions = new ArrayList(100);

    // ����No�Ǝx��No�̗����ڂ��ݒ肳��Ă��Ȃ��ꍇ
    if ((XxcmnUtility.isBlankOrNull(headerNumber))
      && (XxcmnUtility.isBlankOrNull(requestNumber)))
    {
      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "HeaderNumber",
                            headerNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10035));

      exceptions.add( new OAAttrValException(
                            OAAttrValException.TYP_VIEW_OBJECT,
                            vo.getName(),
                            row.getKey(),
                            "RequestNumber",
                            requestNumber,
                            XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10035));

    }

    OAException.raiseBundledOAException(exceptions);

  } // doRequiredCheck2

  /***************************************************************************
   * (��������ڍ׉��)��ʃp�����[�^���擾���郁�\�b�h�ł��B
   * @return HashMap ��ʃp�����[�^
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap getDetailPageParams() throws OAException
  {
    // ************************************** //
    // * ��������ڍ�:��������ڍ�PVO�擾   * //
    // ************************************** //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();

    HashMap retHashMap = new HashMap();

    retHashMap.put("pStartCondition", orderReceiptDetailsPVORow.getAttribute("pStartCondition")); // �N������
    retHashMap.put("pHeaderNumber", orderReceiptDetailsPVORow.getAttribute("pHeaderNumber"));     // �����ԍ�
    retHashMap.put("HeaderNumber", orderReceiptDetailsPVORow.getAttribute("HeaderNumber"));       // �����ԍ�

    return retHashMap;

  } // getDetailPageParams

  /***************************************************************************
   * (��������ڍ׉��)�����������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   * @throws OAException - OA��O
   ***************************************************************************
   */
  public void doSearch2(
    HashMap searchParams
  ) throws OAException
  {
    // ���������擾
    String headerNumber  = (String)searchParams.get("HeaderNumber");  // ����No
    String requestNumber = (String)searchParams.get("RequestNumber"); // �x��No

    // ******************************************* //
    // * ��������ڍ�:��������ڍ�PVO ��s�擾   * //
    // ******************************************* //
    OAViewObject orderReceiptDetailsPVO = getXxpoOrderReceiptDetailsPVO1();
    OARow orderReceiptDetailsPVORow = (OARow)orderReceiptDetailsPVO.first();

    // **************************************** //
    // * ��������ڍ�:�����w�b�_VO ��s�擾   * //
    // **************************************** //
    XxpoOrderHeaderVOImpl orderHeaderVO = getXxpoOrderHeaderVO1();

    // �������{
    orderHeaderVO.initQuery(searchParams);

    // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (orderHeaderVO.getRowCount() == 0)
    {
      // ************************ //
      // * ���ڐ���             * //
      // ************************ //
      // �K�p�{�^����ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);
      // �����{�^����ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                    XxcmnConstants.APPL_XXCMN,
                    XxcmnConstants.XXCMN10500,
                    null,
                    OAException.ERROR,
                    null);
    }

    // ***************************************** //
    // * ��������ڍ�:�o�^�w�b�_VO ���͐���    * //
    // ***************************************** //
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();
    String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");

    // �X�e�[�^�X��"���z�m���"(35)�̏ꍇ
    if (XxpoConstants.STATUS_FINISH_DECISION_MONEY.equals(statusCode))
    {
      // �w�b�_.�E�v��ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.TRUE);
    } else 
    {
      // �w�b�_.�E�v��ReadOnly������
      orderReceiptDetailsPVORow.setAttribute("DescriptionReadOnly",  Boolean.FALSE);
    }

    headerNumber  = (String)orderHeaderVO.first().getAttribute("HeaderNumber");
    requestNumber = (String)orderHeaderVO.first().getAttribute("RequestNumber");
    orderReceiptDetailsPVORow.setAttribute("HeaderNumber",  headerNumber);
    orderReceiptDetailsPVORow.setAttribute("RequestNumber", requestNumber);


    // ************************************** //
    // * ��������ڍ�:��������VO ��s�擾   * //
    // ************************************** //
    XxpoOrderDetailsTabVOImpl orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVOow = null;

    // �������{
    orderDetailsTabVO.initQuery(headerNumber);

    // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (orderDetailsTabVO.getRowCount() == 0)
    {
      // ************************ //
      // * ���ڐ���             * //
      // ************************ //
      // �K�p�{�^����ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);
      // �����{�^����ReadOnly�֕ύX
      orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500,
                  null,
                  OAException.ERROR,
                  null);
    }

    // ************************************************* //
    // * ��������ڍ�:���v�Z�oVO �����\���s�擾        * //
    // ************************************************* //
    XxpoOrderDetailTotalVOImpl orderDetailTotalVO = getXxpoOrderDetailTotalVO1();

    // �������{
    orderDetailTotalVO.initQuery(headerNumber);
    orderDetailTotalVO.first();
    
    // ************************ //
    // * ���ڐ���             * //
    // ************************ //
    // �K�p�{�^����ReadOnly������
    orderReceiptDetailsPVORow.setAttribute("ApplyReadOnly", Boolean.FALSE);
    // ����No��ReadOnly�֕ύX
    orderReceiptDetailsPVORow.setAttribute("HeaderNumberReadOnly",  Boolean.TRUE);
    // �x��No��ReadOnly�֕ύX
    orderReceiptDetailsPVORow.setAttribute("RequestNumberReadOnly", Boolean.TRUE);
    // �����{�^����ReadOnly�֕ύX
    orderReceiptDetailsPVORow.setAttribute("SearchButtonReadOnly",  Boolean.TRUE);

    // ***************************************** //
    // * ��������ڍ�:��������VO ���͐���      * //
    // ***************************************** //
    if (orderDetailsTabVO.getRowCount() > 0)
    {
      // �������ׂ̓��͐�������{
      readOnlyChangedDetailsTab();
    }
    
  } // doSearch2

  /***************************************************************************
   * (��������ڍ׉��)�������ύX�������ł��B
   * @param params �p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void productedDateChanged(
    HashMap params
  ) throws OAException
  {
    // �ܖ������擾
    getUseByDate(params);
  } // productedDateChanged

  /***************************************************************************
   * (��������ڍ׉��)�ܖ��������擾���郁�\�b�h�ł��B
   * @param params �p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getUseByDate(
    HashMap params
  ) throws OAException
  {
    String searchLineNum = 
      (String)params.get(XxpoConstants.URL_PARAM_CHANGED_LINE_NUMBER);

    // �o�^����VO�擾
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    // 1�s�߂��擾
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while(orderDetailsTabVO.getCurrentRow() != null)
    {
      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();
      
      if (searchLineNum.equals(orderDetailsTabVORow.getAttribute("LineNum").toString()))
      {
        break;
      }
      
      orderDetailsTabVO.next();
      
    }

    // �f�[�^�擾
    Date productedDate   = (Date)orderDetailsTabVORow.getAttribute("ProductionDate");  // ������
    Number itemId        = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");     // OPM�i��ID
    Number expirationDay = (Number)orderDetailsTabVORow.getAttribute("ExpirationDay"); // �ܖ�����

    // �����������͂���Ă��Ȃ�(�폜���ꂽ)�ꍇ�͎Z�o���s��Ȃ�
    if (productedDate != null)
    {
      // �ܖ����Ԃɒl������ꍇ�A�ܖ������擾
      if (!XxcmnUtility.isBlankOrNull(expirationDay))
      {

        Date useByDate = XxpoUtility.getUseByDate(
                           getOADBTransaction(),      // �g�����U�N�V����
                           itemId,                    // OPM�i��ID
                           productedDate,             // ������
                           expirationDay.toString()); // �ܖ�����

        // �ܖ��������O���o�������:�o�^VO�ɃZ�b�g
        orderDetailsTabVORow.setAttribute("UseByDate", useByDate);
    
      // �ܖ����Ԃɒl���Ȃ��ꍇ�ANULL
      } else
      {
        // �ܖ��������d����o�׎��я��:�o�^����VO�ɃZ�b�g
        orderDetailsTabVORow.setAttribute("UseByDate", productedDate);
      }
    }
  } // getUseByDate

  /***************************************************************************
   * (��������ڍ׉��)�o�^�E�X�V�O�`�F�b�N�������s���܂��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void dataCheck() throws OAException
  {
    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    
    // ********************************** //
    // * ����1:���͍��ڃ`�F�b�N�����{   * //
    // *   1-1:�������͒l�`�F�b�N       * //
    // ********************************** //
    messageTextInputCheck2(exceptions);

    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

  } // dataCheck

  /***************************************************************************
   * (��������ڍ׉��)���ړ��͒l�`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextInputCheck2(
    ArrayList exceptions
  ) throws OAException
  {
    // ��������ڍ�:��������VO�擾
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // ************************************ //
      // * ����1-1:�������͒l�`�F�b�N   * //
      // ************************************ //
      // �s�P�ʂł̓����`�F�b�N�����{
      messageTextQuantityRowCheck2(orderDetailsTabVO,
                                   orderDetailsTabVORow,
                                   exceptions);

      orderDetailsTabVO.next();

    }

  } // messageTextInputCheck2

  /***************************************************************************
   * (��������ڍ׉��)�s�P�ʂœ����`�F�b�N���s�����\�b�h�ł��B
   * @param checkVo �`�F�b�N�Ώ�VO
   * @param checkRow �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextQuantityRowCheck2(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // �������擾
    String itemAmount = (String)checkRow.getAttribute("ItemAmount");

    // ************************************ //
    // * ����1-1:�������͒l�`�F�b�N       * //
    // ************************************ //
    // ������0�����̏ꍇ�̓G���[
    if (!XxcmnUtility.isBlankOrNull(itemAmount))
    {
      // ���l�łȂ��ꍇ�̓G���[
      if (!XxcmnUtility.chkNumeric(XxcmnUtility.commaRemoval(itemAmount), 5, 3))
      {

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10001));

      // 0�ȉ��̓G���[
      } else if(!XxcmnUtility.chkCompareNumeric(2, XxcmnUtility.commaRemoval(itemAmount), "0"))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY,
                                     XxpoConstants.TOKEN_NAME_ITEM_AMOUNT);

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "ItemAmount",
                              itemAmount,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10068,
                              tokens));

      }
    }
  } // messageTextQuantityRowCheck2

  /***************************************************************************
   * (��������ڍ׉��)�o�^�X�V�������s�����\�b�h�ł��B
   * @return String ����(�X�V�L):xcmnConstants.STRING_TRUE�A
   *                 ����(�X�V��):xcmnConstants.RETURN_SUCCESS�A
   *                 ���s:xcmnConstants.RETURN_NOT_EXE
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String apply() throws OAException
  {

    // �o�^�X�V��������
    String retCode = XxcmnConstants.RETURN_NOT_EXE;
    // �X�V�m�F�t���O
    boolean updFlag = false;

    // ******************************** //
    // * �����w�b�_�X�V����           * //
    // ******************************** //
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // �����w�b�_���b�N�擾����
    getHeaderRowLock(
      (Number)orderHeaderVORow.getAttribute("HeaderId"));

    // �����w�b�_�r������
    chkHdrExclusiveControl(
      (Number)orderHeaderVORow.getAttribute("HeaderId"),
      (String)orderHeaderVORow.getAttribute("LastUpdateDate"));

    
    if (!XxcmnUtility.isEquals(orderHeaderVORow.getAttribute("Description"),
           orderHeaderVORow.getAttribute("BaseDescription")))
    {

      // �X�V�t���O��true��
      updFlag = true;

      // �����w�b�_�[�X�V�F���s
      retCode = updHeaderDesc(orderHeaderVORow);

      // �X�V����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {

        return XxcmnConstants.RETURN_NOT_EXE;
      }

    }

    // ******************************** //
    // * �������ׁE���b�gMST�X�V����  * //
    // ******************************** //
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    orderDetailsTabVO.first();

    while (orderDetailsTabVO.getCurrentRow() != null)
    {

      orderDetailsTabVORow = (OARow)orderDetailsTabVO.getCurrentRow();

      // �������׃��b�N�擾����
      getDetailsRowLock(
        (Number)orderDetailsTabVORow.getAttribute("LineId"));

      // �������הr������
      chkDetailsExclusiveControl(
        (Number)orderDetailsTabVORow.getAttribute("LineId"),
        (String)orderDetailsTabVORow.getAttribute("LastUpdateDate"));

      // ******************************** //
      // * �������׍X�V����             * //
      // ******************************** //
      String baseItemAmount = (String)orderDetailsTabVORow.getAttribute("BaseItemAmount");
      // (DB)�������擾����Ă���ꍇ�́A�J���}������
      if (!XxcmnUtility.isBlankOrNull(baseItemAmount))
      {
        baseItemAmount = XxcmnUtility.commaRemoval(baseItemAmount);
      }
      
// 20080523 add yoshimoto Start
      String itemAmount = XxcmnUtility.commaRemoval(
                            (String)orderDetailsTabVORow.getAttribute("ItemAmount"));
// 20080523 add yoshimoto End      
      if ((!XxcmnUtility.chkCompareNumeric(3, itemAmount, baseItemAmount))
        || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("Description"),
               orderDetailsTabVORow.getAttribute("BaseDescription"))))
      {

        // �X�V�t���O��true��
        updFlag = true;

        // �������׍X�V�F���s
        retCode = updItemAmountAndDesc(orderDetailsTabVORow);

        // �X�V����������I���łȂ��ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {

          return XxcmnConstants.RETURN_NOT_EXE;
        } 

      }

      // ******************************** //
      // * ���b�gMST�X�V����            * //
      // ******************************** //
      // �i�ڂ����b�g�Ώۂł���ꍇ
      Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {

        // ���b�gMST���b�N�擾����
        getOpmLotMstRowLock(
          (String)orderDetailsTabVORow.getAttribute("LotNo"),      // ���b�gNo
          (Number)orderDetailsTabVORow.getAttribute("OpmItemId")); // OPM�i��ID

        // ���b�gMST�r������
        chkOpmLotMstExclusiveControl(
          (String)orderDetailsTabVORow.getAttribute("LotNo"),              // ���b�gNo
          (Number)orderDetailsTabVORow.getAttribute("OpmItemId"),          // OPM�i��ID
          (String)orderDetailsTabVORow.getAttribute("LotLastUpdateDate")); // �ŏI�X�V��

        if ((!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("ProductionDate"),
                orderDetailsTabVORow.getAttribute("BaseProductionDate")))
          || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("UseByDate"),
                 orderDetailsTabVORow.getAttribute("BaseUseByDate")))
// 20080523 add yoshimoto Start                 
          || (!XxcmnUtility.chkCompareNumeric(3, itemAmount, baseItemAmount))
          || (!XxcmnUtility.isEquals(orderDetailsTabVORow.getAttribute("Description"),
                 orderDetailsTabVORow.getAttribute("BaseDescription"))))
// 20080523 add yoshimoto End
        {

          // �X�V�t���O��true��
          updFlag = true;

          HashMap setParams = new HashMap();

          // OPM�i��ID
          setParams.put("ItemId", orderDetailsTabVORow.getAttribute("OpmItemId"));
          // ���b�gNo
          setParams.put("LotNo",  orderDetailsTabVORow.getAttribute("LotNo"));
          // ������
          setParams.put("ProductionDate", orderDetailsTabVORow.getAttribute("ProductionDate"));
          // �ܖ�����
          setParams.put("UseByDate", orderDetailsTabVORow.getAttribute("UseByDate"));

// 20080523 add yoshimoto Start
          // ����
          setParams.put("ItemAmount", itemAmount);
          // ���דE�v
          setParams.put("Description", orderDetailsTabVORow.getAttribute("Description"));
// 20080523 add yoshimoto End

          // ���b�gMST�X�V�F���s
          retCode = XxpoUtility.updateIcLotsMstTxns2(
                      getOADBTransaction(),
                      setParams);

          // �X�V����������I���łȂ��ꍇ
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            return XxcmnConstants.RETURN_NOT_EXE;
          } 

        }
      }

      orderDetailsTabVO.next();
    }

    // �X�V���s���Ă���ꍇ�́ASTRING_TRUE��Ԃ�
    if (updFlag)
    {
      return XxcmnConstants.STRING_TRUE;
      
    }
    
    // �X�V���s���Ă��Ȃ����A����I���̏ꍇ��RETURN_SUCCESS��Ԃ�
    return XxcmnConstants.RETURN_SUCCESS;
  } // apply
 
  /***************************************************************************
   * (��������ڍ׉��)�S��X�V�O�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public ArrayList chkAllReceipt() throws OAException
  {
    ArrayList exceptions = new ArrayList();
    ArrayList lineIdList = new ArrayList();
    
    // �S��ON�L���t���O
    boolean allReceiptFlag = false;

    // ******************************** //
    // * �������ׁE���b�gMST�X�V����  * //
    // ******************************** //
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    Row[]rows = orderDetailsTabVO.getFilteredRows("AllReceipt", XxcmnConstants.STRING_Y);

    // �t�B���^��A���R�[�h��1�s�ȏ㑶�݂���ꍇ
    if (rows.length > 0)
    {
      // �S��ON�L���t���O��true��
      allReceiptFlag = true;
    }

    for (int i = 0; i < rows.length; i++)
    {

      orderDetailsTabVORow = (OARow)rows[i];

      // *************************************************** //
      // * ����2:����ԕi����(�A�h�I��)�ɓo�^�ς݃`�F�b�N  * //
      // *************************************************** //
      Number lineNumber = (Number)orderDetailsTabVORow.getAttribute("LineNum"); // �������הԍ�

      // �������ׂ̐��ʊm��Flag��'Y'�̏ꍇ�́A���э쐬�ς�
      String decisionAmountFlag = (String)orderDetailsTabVORow.getAttribute("DecisionAmountFlag");

      // �`�F�b�N�ŃG���[�����������ꍇ
      if (XxcmnConstants.STRING_Y.equals(decisionAmountFlag))
      {

        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              orderDetailsTabVO.getName(),
                              orderDetailsTabVORow.getKey(),
                              "LineNum",
                              lineNumber,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10203,
                              null));

      }

    }


    // �S��ON�L���t���O��True�̏ꍇ
    if (allReceiptFlag)
    {
	    // ��������ڍ�:�����w�b�_VO�擾
	    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
	    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();
	    
	    // �[����(�[���\���)���擾
	    Date deliveryDate = (Date)orderHeaderVORow.getAttribute("DeliveryDate");
	    
	    // ************************************ //
	    // * ����3-1:�[�����N���[�Y�`�F�b�N   * //
	    // ************************************ //
	    // �[�������[�����N���[�Y�̏ꍇ�̓G���[
	    if (XxpoUtility.chkStockClose(
	      getOADBTransaction(),
	      deliveryDate))
	    {
	      // �G���[���b�Z�[�W��ǉ�
	      exceptions.add( new OAAttrValException(
	                            OAAttrValException.TYP_VIEW_OBJECT,
	                            orderHeaderVO.getName(),
	                            orderHeaderVORow.getKey(),
	                            "DeliveryDate",
	                            deliveryDate,
	                            XxcmnConstants.APPL_XXPO,
	                            XxpoConstants.XXPO10205));
	    }
	
	    // ************************************************** //
	    // * ����3-1:�������`�F�b�N                         * //
	    // ************************************************** //
	    // �V�X�e�����t���擾
	    Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());
	
	    // �[���\������������̏ꍇ
	    if (XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate))
	    {
	      // ************************ //
	      // * �G���[���b�Z�[�W�o�� * //
	      // ************************ //
	      exceptions.add( new OAAttrValException(
	                            OAAttrValException.TYP_VIEW_OBJECT,
	                            orderHeaderVO.getName(),
	                            orderHeaderVORow.getKey(),
	                            "DeliveryDate",
	                            deliveryDate,
	                            XxcmnConstants.APPL_XXPO,
	                            XxpoConstants.XXPO10204,
	                            null));
	    }
	
	    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
	    if (exceptions.size() > 0)
	    {
	      OAException.raiseBundledOAException(exceptions);
	    }
	
	    // *************************************** //
	    // * ����3-2:�������|���̊m�F          * //
	    // *************************************** //
	    for (int i = 0; i < rows.length; i++)
	    {
	
	      orderDetailsTabVORow = (OARow)rows[i];
	
	      // �[�����ߋ����t�`�F�b�N�t���O
	      boolean dateOfPastFlag = false;
	
	      // ************************************ //
	      // * ���Z�L���`�F�b�N                 * //
	      // ************************************ //
	      boolean conversionFlag = false;
	      String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
	      String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
	      String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");
	
	      // ���Z�L���`�F�b�N�����{
	      conversionFlag = chkConversion(
	                         prodClassCode,  // ���i�敪
	                         itemClassCode,  // �i�ڋ敪
	                         convUnit);      // ���o�Ɋ��Z�P��
	
	      // ************************************ //
	      // * ����쐬�ς݃`�F�b�N             * //
	      // ************************************ //
	      // ���ʊm��t���O���擾
	      String decisionAmountFlag = (String)orderDetailsTabVORow.getAttribute("DecisionAmountFlag");
	      
	      // �������ׂ̐��ʊm��t���O��'Y'�̏ꍇ
	      if (!XxcmnConstants.STRING_Y.equals(decisionAmountFlag))
	      {
	
	        // �[�����\������ߋ����t�̏ꍇ(SYSDATE > �[���\���)
	        if (XxcmnUtility.chkCompareDate(1, sysDate, deliveryDate))
	        {
	
	          String locationCode = (String)orderHeaderVORow.getAttribute("LocationCode");
	          Number opmItemId    = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");
	          Number lotId        = (Number)orderDetailsTabVORow.getAttribute("LotId");
	
	          // ************************************* //
	          // * �����\���ʂ��擾                * //
	          // *   paramsRet(0) : �L���������\�� * //
	          // *   paramsRet(1) : �������\��     * //
	          // ************************************* //
	          HashMap paramsRet = XxpoUtility.getReservedQuantity(
	                                            getOADBTransaction(),
	                                            opmItemId,            // OPM�i��ID
	                                            locationCode,         // �[����R�[�h
	                                            lotId);               // ���b�gID
	
	          // �������ʂ��擾
	          String orderAmount = (String)orderDetailsTabVORow.getAttribute("OrderAmount");
	          // �J���}�y�я����_������
	          String sOrderAmount = XxcmnUtility.commaRemoval(orderAmount);
	
	          // �݌ɓ���
	          String itemAmount = (String)orderDetailsTabVORow.getAttribute("ItemAmount");
	          // �J���}�y�я����_������
	          String sItemAmount = XxcmnUtility.commaRemoval(itemAmount);
	
	          // ���Z���K�v�ȏꍇ�́A�݌ɓ����ŏ�Z
	          if (conversionFlag)
	          {
	            double dOrderAmount = Double.parseDouble(sOrderAmount) * Double.parseDouble(sItemAmount);
	            sOrderAmount = Double.toString(dOrderAmount);
	          }
	
	          // ************************************ //
	          // * �����|���`�F�b�N               * //
	          // ************************************ //
	          // �L�����x�[�X�����\��
	          Object inTimeQty = paramsRet.get("InTimeQty");
	          // �������\��
	          Object totalQty  = paramsRet.get("TotalQty");
	
	          // �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
	          if ((XxcmnUtility.chkCompareNumeric(1, sOrderAmount, inTimeQty.toString()))
	            || (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, totalQty.toString())))
	          {
	
	            // �������|���̊m�F(�x��)
	            // lineId��ݒ�
	            lineIdList.add(orderDetailsTabVORow.getAttribute("LineId"));
	
            }
          }
        }
      }

    }

    return lineIdList;
  } // chkAllReceipt

  /***************************************************************************
   * (��������ڍ׉��)�����w�b�_�̓E�v���X�V���郁�\�b�h�ł��B
   * @param row �X�V�Ώۍs
   * @return String ����FTRUE�A�G���[�FFALSE
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String updHeaderDesc(OARow row) throws OAException
  {

    HashMap params = new HashMap();

    Number HeaderId = (Number)row.getAttribute("HeaderId");
    // �w�b�_�[ID
    params.put("HeaderId",    HeaderId.toString());
    // �K�p
    params.put("Description", row.getAttribute("Description"));

    // �����w�b�_�[�X�V�F���s
    String retCode = XxpoUtility.updatePoHeadersAllTxns(
                       getOADBTransaction(), // �g�����U�N�V����
                       params);              // �p�����[�^

    // �X�V����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      return XxcmnConstants.STRING_FALSE;
    }

    return XxcmnConstants.STRING_TRUE;

  } // updHeaderDesc

  /***************************************************************************
   * (��������ڍ׉��)�������ׂ̍݌ɓ���/�E�v���X�V���郁�\�b�h�ł��B
   * @param row �X�V�Ώۍs
   * @return String ����FTRUE
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String updItemAmountAndDesc(
    OARow row
  ) throws OAException
  {

    HashMap params = new HashMap();

    // �݌ɓ���
    String itemAmount = (String)row.getAttribute("ItemAmount");
    // �J���}�y�я����_������
    String sItemAmount = XxcmnUtility.commaRemoval(itemAmount);
    

    // ����ID
    params.put("LineId",      row.getAttribute("LineId"));
    // �݌ɓ���
    params.put("ItemAmount",  sItemAmount);
    // ���דK�p
    params.put("Description", row.getAttribute("Description"));

    // �������׍X�V�F���s
    XxpoUtility.updateItemAmount(
                  getOADBTransaction(), // �g�����U�N�V����
                  params);              // �p�����[�^

    return XxcmnConstants.STRING_TRUE;

  } // updItemAmountAndDesc

  /***************************************************************************
   * (��������ڍ׉��)�g�[�N���p�̏����擾���郁�\�b�h�ł��B
   * @param lineId ��������ID
   * @return HashMap �g�[�N��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap getToken(
    Number lineId
  ) throws OAException
  {
    // �g�[�N�����i�[
    HashMap tokens = new HashMap();

    // �����w�b�_VO���擾
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // ��������VO���擾
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow     = (OARow)orderDetailsTabVO.getFirstFilteredRow("LineId", lineId);

    // �[���於
    tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderHeaderVORow.getAttribute("LocationName"));
    // �i�ږ�
    tokens.put(XxcmnConstants.TOKEN_ITEM,     (String)orderDetailsTabVORow.getAttribute("OpmItemName"));
    // ���b�gNo
    tokens.put(XxcmnConstants.TOKEN_LOT,      (String)orderDetailsTabVORow.getAttribute("LotNo"));

    return tokens;
  } // getToken

  /***************************************************************************
   * (��������ڍ׉��)�S�󏈗����s�����\�b�h�ł��B
   * @return HashMap ����(�X�V�L):xcmnConstants.STRING_TRUE�A
   *                 ����(�X�V��):xcmnConstants.RETURN_SUCCESS�A
   *                 ���s:xcmnConstants.RETURN_NOT_EXE
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap doAllReceipt() throws OAException
  {

    // �o�^��������
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // �����w�b�_VO���擾
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // ��������VO���擾
    OAViewObject orderDetailsTabVO = getXxpoOrderDetailsTabVO1();
    OARow orderDetailsTabVORow = null;

    // ���v�������
    double receiptAmountTotal = 0.000;

    // ���ID
    Number txnsId = null;

    // �O���[�vID
    Number groupId = null;
    String retGroupId = null;


    Row[] rows = orderDetailsTabVO.getFilteredRows("AllReceipt", XxcmnConstants.STRING_Y);

    for (int i = 0; i < rows.length; i++)
    {

      orderDetailsTabVORow = (OARow)rows[i];

      // ********************************************** //
      // * ����3-4:����ԕi����(�A�h�I��)�o�^����     * //
      // ********************************************** //
      retHashMap = (HashMap)insRcvAndRtnTxns(
                              orderHeaderVORow, 
                              orderDetailsTabVORow);

      retCode = (String)retHashMap.get("RetFlag");

      // �o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // ����ԕi����(�A�h�I��).���ID���擾
      txnsId = (Number)retHashMap.get("TxnsId");

      // �������ʂ��擾
      String orderAmount = (String)orderDetailsTabVORow.getAttribute("OrderAmount");

      // �J���}������
      orderAmount = XxcmnUtility.commaRemoval(orderAmount);

      // �������ʂ�0��葽���ꍇ
      if (XxcmnUtility.chkCompareNumeric(1, orderAmount, "0"))
      {
        // ************************************************ //
        // * ����3-3:����I�[�v���C���^�t�F�[�X�o�^����   * //
        // ************************************************ //
        retHashMap = insOpenIf(
                       orderHeaderVORow,
                       orderDetailsTabVORow,
                       txnsId,
                       groupId);

        retCode = (String)retHashMap.get("RetFlag");
        retGroupId = retCode.toString();
        
        // �o�^����������I���łȂ��ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
          return retHashMap;
        }

        // �O���[�vID��ޔ�
        groupId = (Number)retHashMap.get("GroupId");
        retGroupId = groupId.toString();
      }

      // *********************************** //
      // * ����3-5:�������׍X�V����        * //
      // *********************************** //
      // �����c��
      String orderRemainder = XxcmnUtility.commaRemoval(             // �J���}������
                                (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
      double dorderRemainder = Double.parseDouble(orderRemainder);   // double�^�֕ϊ�
    
      // �X�V����
      XxpoUtility.updateReceiptAmount(
        getOADBTransaction(),
        (Number)orderDetailsTabVORow.getAttribute("LineId"),
        dorderRemainder);

      // *********************************** //
      // * ����3-6:���b�g�X�V����          * //
      // *********************************** //
      // �i�ڂ����b�g�Ώۂł���ꍇ
      Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
      if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
      {

        // �X�V����
        updIcLotsMstTxns(
          orderHeaderVORow,
          orderDetailsTabVORow);

      }

      // ************************************ //
      // * ����3-9:�݌ɐ���API�N������      * //
      // ************************************ //
      // �����敪���擾
      String orderDivision = (String)orderHeaderVORow.getAttribute("OrderDivision");

      // �����敪�������݌ɂł���ꍇ
      if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
      {
        insIcTranCmp(txnsId,
                     orderHeaderVORow,
                     orderDetailsTabVORow); // ���ID

      }
// 20080523 del yoshimoto Start
    //}
// 20080523 del yoshimoto End

      // ********************************************** //
      // * ����3-7,8:�����X�e�[�^�X�ύX����           * //
      // ********************************************** //
      chgStatus();
      
// 20080523 add yoshimoto Start
    }
// 20080523 add yoshimoto End

    // ********************************************** //
    // * ����4:�������������N��                   * //
    // ********************************************** //
    if (!XxcmnUtility.isBlankOrNull(groupId))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      retHashMap = XxpoUtility.doRVCTP(
                      getOADBTransaction(),
                      groupId.toString());

      return retHashMap;
    }

    // �S�Ă̏���������ɏI�����Ă���ꍇ
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
    return retHashMap;
    
  } // doAllReceipt

  /***************************************************************************
   * (��������ڍ׉��)����ԕi����(�A�h�I��)�o�^�������s�����\�b�h�ł��B
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insRcvAndRtnTxns(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ���ы敪
    setParams.put("TxnsType",               "1");
    // ����ԕi�ԍ�
    setParams.put("RcvRtnNumber",           orderHeaderVORow.getAttribute("HeaderNumber"));
    // �������ԍ�
    setParams.put("SourceDocumentNumber",   orderHeaderVORow.getAttribute("HeaderNumber"));
    // �����ID
    setParams.put("VendorId",               orderHeaderVORow.getAttribute("VendorId"));
    // �����R�[�h
    setParams.put("VendorCode",             orderHeaderVORow.getAttribute("VendorCode"));
    // ���o�ɐ�R�[�h
    setParams.put("LocationCode",           orderHeaderVORow.getAttribute("LocationCode"));
    // ���������הԍ�
    setParams.put("SourceDocumentLineNum",  orderDetailsTabVORow.getAttribute("LineNum"));
    // ����ԕi���הԍ�
    setParams.put("RcvRtnLineNumber",       new Number(1));
    // �i��ID
    setParams.put("ItemId",                 orderDetailsTabVORow.getAttribute("OpmItemId"));
    // �i�ڃR�[�h
    setParams.put("ItemCode",               orderDetailsTabVORow.getAttribute("OpmItemNo"));
    // ���b�gID
    setParams.put("LotId",                  orderDetailsTabVORow.getAttribute("LotId"));
    // ���b�gNo
    setParams.put("LotNumber",              orderDetailsTabVORow.getAttribute("LotNo"));
    // �����
    setParams.put("TxnsDate",               orderHeaderVORow.getAttribute("DeliveryDate"));

    // ����ԕi����(�����c��)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double�^�֕ϊ�

    setParams.put("RcvRtnQuantity",  new Double(dRcvRtnQuantity).toString());
    // ����ԕi�P��
    setParams.put("RcvRtnUom",       orderDetailsTabVORow.getAttribute("UnitName"));
    // �P�ʃR�[�h
    setParams.put("Uom",             orderDetailsTabVORow.getAttribute("UnitMeasLookupCode"));
    // ���דE�v
    setParams.put("LineDescription", "");
    // �����敪
    setParams.put("DropshipCode",    orderDetailsTabVORow.getAttribute("DropshipCode"));
    // �P��
    setParams.put("UnitPrice",       orderDetailsTabVORow.getAttribute("UnitPrice"));
// 20080520 add yoshimoto Start
    // ���������R�[�h
    setParams.put("DepartmentCode",  orderHeaderVORow.getAttribute("DepartmentCode"));
// 20080520 add yoshimoto End

    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ����
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // ���Z�����F���Z�����𔭒�����.�����Ƃ���
      setParams.put("ConversionFactor", sItemAmount);


    // ���Z���s�v�ȏꍇ
    } else
    {

      // ����
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // ���Z�����F���Z������1�Ƃ���
      setParams.put("ConversionFactor", new Integer(1).toString());

    }

    // ************************************ //
    // * ����ԕi����(�A�h�I��)�o�^����   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvAndRtnTxns

  /***************************************************************************
   * (��������ڍ׉��)OIF�o�^�������s�����\�b�h�ł��B
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @param txnsId ���ID
   * @param groupId �O���[�vID
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insOpenIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * ����w�b�_OIF�o�^����              * //
    // ************************************** //
    retHashMap = insRcvHeadersIf(
                   orderHeaderVORow,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");

    // �o�^�E��������������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    Number headerInterfaceId = (Number)retHashMap.get("HeaderInterfaceId");
    groupId  = (Number)retHashMap.get("GroupId");

    // ************************************** //
    // * ����g�����U�N�V����OIF�o�^����    * //
    // ************************************** //
    retHashMap = insRcvTransactionsIf(
                   orderHeaderVORow, 
                   orderDetailsTabVORow,
                   txnsId,
                   headerInterfaceId,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");
    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    // �o�^����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;

    }


    // �i�ڂ����b�g�Ώۂł���ꍇ
    Number lotCtl = (Number)orderDetailsTabVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * �i�ڃ��b�g�g�����U�N�V����OIF�o�^����    * //
      // ******************************************** //
      retCode = insMtlTransactionLotsIf(
                  orderHeaderVORow, 
                  orderDetailsTabVORow,
                  interfaceTransactionId);

      // �o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // insOpenIf

  /***************************************************************************
   * (��������ڍ׉��)����g�����U�N�V����OIF�o�^�������s�����\�b�h�ł��B
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @param txnsId ���ID
   * @param headerInterfaceId ����w�b�_OIF.header_interface_id
   * @param groupId ����w�b�_OIF.group_id
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insRcvTransactionsIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number txnsId,
    Number headerInterfaceId,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // ����ԕi����(�����c��)
    /*String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));*/

    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)orderDetailsTabVORow.getAttribute("OrderAmount"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double�^�֕ϊ�

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.�[����R�[�h
    setParams.put("LocationCode",       orderHeaderVORow.getAttribute("LocationCode"));
    // ��������ID
    setParams.put("LineId",             orderDetailsTabVORow.getAttribute("LineId"));
    // ����w�b�_OIF��GROUP_ID�Ɠ��l���w��
    setParams.put("GroupId",            groupId);
    // �[����(�[���\���)
    setParams.put("TxnsDate",           orderHeaderVORow.getAttribute("DeliveryDate"));
    // ��������.�i�ڊ�P��
    setParams.put("UnitMeasLookupCode", orderDetailsTabVORow.getAttribute("UnitMeasLookupCode"));  
    // ��������.�i��ID(ITEM_ID)
    setParams.put("PlaItemId",          orderDetailsTabVORow.getAttribute("PlaItemId"));
    // �����w�b�_.�����w�b�_ID
    setParams.put("HeaderId",           orderHeaderVORow.getAttribute("HeaderId"));
    // �����w�b�_.�[����
    setParams.put("DeliveryDate",       orderHeaderVORow.getAttribute("DeliveryDate"));
    // ����ԕi����(�A�h�I��)�̎��ID
    setParams.put("TxnsId",             txnsId);
    // ����w�b�_OIF��INTERFACE_TRANSACTION_ID
    setParams.put("HeaderInterfaceId",  headerInterfaceId);


    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ������ʂ�����Ŋ��Z
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ************************************ //
    // * ����g�����U�N�V����OIF�o�^����   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvTransactionsIf

  /***************************************************************************
   * (��������ڍ׉��)�i�ڃ��b�g�g�����U�N�V����OIF�o�^�������s�����\�b�h�ł��B
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @param interfaceTransactionId ����g�����U�N�V����OIF.interface_transaction_id
   * @return String �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String insMtlTransactionLotsIf(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsTabVORow.getAttribute("ItemAmount"));

    // ����ԕi����(�����c��)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double�^�֕ϊ�

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.���b�gNo
    setParams.put("LotNo",              orderDetailsTabVORow.getAttribute("LotNo"));
    // ����g�����U�N�V����OIF��INTERFACE_TRANSACTION_ID
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);

    // ���Z���K�v�ȏꍇ
    if (conversionFlag) 
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ******************************************* //
    // * �i�ڃ��b�g�g�����U�N�V����OIF�o�^����   * //
    // ******************************************* //
    String retCode = XxpoUtility.insertMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // insMtlTransactionLotsIf

  /***************************************************************************
   * (��������ڍ׉��)�݌ɐ���API�N���������s�����\�b�h�ł��B
   * @param txnsId ���ID
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void insIcTranCmp(
    Number txnsId,
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    setParams.put("LocationCode",       orderDetailsTabVORow.getAttribute("VendorStockWhse"));    // �ۊǏꏊ(�����݌ɓ��ɐ�)
    setParams.put("ItemNo",             orderDetailsTabVORow.getAttribute("OpmItemNo"));          // �i��(OPM�i�ږ�)
    setParams.put("UnitMeasLookupCode", orderDetailsTabVORow.getAttribute("UnitMeasLookupCode")); // �i�ڊ�P��
    setParams.put("LotNo",              orderDetailsTabVORow.getAttribute("LotNo"));              // ���b�g
    setParams.put("TxnsDate",           orderHeaderVORow.getAttribute("DeliveryDate"));           // �����(�����w�b�_.�[�����\���)
    setParams.put("ReasonCode",         XxpoConstants.CTPTY_INV_SHIP_RSN);                        // ���R�R�[�h(XXPO_CTPTY_INV_SHIP_RSN)
    setParams.put("TxnsId",             txnsId);                                                  // �����\�[�XID(����ԕi����(�A�h�I��).���ID)

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsTabVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsTabVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsTabVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ����ԕi����(�����c��)
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)orderDetailsTabVORow.getAttribute("OrderRemainder"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double�^�֕ϊ�


    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      // ���Z�������擾
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsTabVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ��������
      // �������� * ���� * (-1)
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount * (-1);


      // �������(���Z����)
      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // ������� * (-1)
      dRcvRtnQuantity = dRcvRtnQuantity * (-1);

      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    }

    // �݌ɐ���API���N��
    XxpoUtility.insertIcTranCmp(
      getOADBTransaction(),
      setParams);

  } // insIcTranCmp

  /***************************************************************************
   * (��������ڍ׉��)OPM���b�gMST�X�V�������s�����\�b�h�ł��B
   * @param orderHeaderVORow �����w�b�_
   * @param orderDetailsTabVORow ��������
   * @return String �X�V��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String updIcLotsMstTxns(
    OARow orderHeaderVORow,
    OARow orderDetailsTabVORow
  ) throws OAException
  {

    // ���b�gNo���擾
    String lotNo     = (String)orderDetailsTabVORow.getAttribute("LotNo");
    // OPM�i��ID���擾
    Number opmItemId = (Number)orderDetailsTabVORow.getAttribute("OpmItemId");
    // OPM���b�gMST�ŏI�X�V�����擾
    String lotLastUpdateDate   = (String)orderDetailsTabVORow.getAttribute("LotLastUpdateDate");
    // OPM���b�gMST.�[����(����)
    Date firstTimeDeliveryDate = (Date)orderDetailsTabVORow.getAttribute("FirstTimeDeliveryDate");
    // OPM���b�gMST.�[����(�ŏI)
    Date finalDeliveryDate     = (Date)orderDetailsTabVORow.getAttribute("FinalDeliveryDate");

    HashMap setParams = new HashMap();

    // ************************************ //
    // * �����w�b�_�̔[���\������擾     * //
    // ************************************ //
    Date deliveryDate = (Date)orderHeaderVORow.getAttribute("DeliveryDate");

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    setParams.put("LotNo", lotNo);
    setParams.put("ItemId", opmItemId);

    // OPM���b�gMST.�[����(����)���u�����N(Null)�ł���A
    //   �܂��́A�����w�b�_.�[���\�����OPM���b�gMST.�[����(����)���ߋ����̏ꍇ
    if (XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, firstTimeDeliveryDate, deliveryDate))
    {

      setParams.put("FirstTimeDeliveryDate", deliveryDate.toString());    // �[����(����)

    }

    // OPM���b�gMST.�[����(�ŏI)���u�����N(Null)�ł���A
    //   �܂��́A�����w�b�_.�[���\�����OPM���b�gMST.�[����(�ŏI)��薢�����̏ꍇ
    if (XxcmnUtility.isBlankOrNull(finalDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, deliveryDate, finalDeliveryDate))
    {

      setParams.put("FinalDeliveryDate", deliveryDate.toString());       // �[����(�ŏI)

    }

    // ****************** //
    // * �X�V����       * //
    // ****************** //
    XxpoUtility.updateIcLotsMstTxns2(
      getOADBTransaction(),
      setParams);

    return XxcmnConstants.RETURN_SUCCESS;

  } // updIcLotsMstTxns

  /***************************************************************************
   * (��������ڍ׉��)�����w�b�_.�X�e�[�^�X�ύX���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chgStatus()
  throws OAException
  {
    // �����w�b�_VO���擾
    OAViewObject orderHeaderVO = getXxpoOrderHeaderVO1();
    OARow orderHeaderVORow = (OARow)orderHeaderVO.first();

    // ���݂̃X�e�[�^�X�R�[�h���擾
    String statusCode = (String)orderHeaderVORow.getAttribute("StatusCode");
    // �����w�b�_ID���擾
    Number headerId = (Number)orderHeaderVORow.getAttribute("HeaderId");

    // �����w�b�_�ɕR�t���S�Ă̔������ׂ̐��ʊm��t���O��'Y'�ł��邩���m�F
    String chkAllFinDecisionAmountFlg = XxpoUtility.chkAllFinDecisionAmountFlg(
                                          getOADBTransaction(),
                                          headerId);

    // �����w�b�_�ɕR�t���S�Ă̔������ׂ̐��ʊm��t���O��'Y'�̏ꍇ
    if (XxcmnConstants.STRING_Y.equals(chkAllFinDecisionAmountFlg))
    {

      // �X�V����(�X�e�[�^�X�R�[�h�F���ʊm���(20))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_FINISH_DECISION_AMOUNT,  // ���ʊm���(20)
        headerId);                                    // �����w�b�_ID

    // ���݂̃X�e�[�^�X���A�����쐬��(20)�̏ꍇ
    } else if (XxpoConstants.STATUS_FINISH_ORDERING_MAKING.equals(statusCode)) 
    {

      // �X�V����(�X�e�[�^�X�R�[�h�F�������(15))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_REPUTATION_CASE, // �������(15)
        headerId);                            // �����w�b�_ID

    }

  } // chgStatus

  /***************************************************************************
   * (����������͉��)�������������s�����\�b�h�ł��B
   * @param searchParams �����p�����[�^�pHashMap
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void initialize3(
    HashMap searchParams
  ) throws OAException
  {

    // ******************************************* //
    // * �����������:�����������PVO ��s�擾   * //
    // ******************************************* //
    OAViewObject orderReceiptMakePVO = getXxpoOrderReceiptMakePVO1();

    // 1�s���Ȃ��ꍇ�A��s�쐬
    if (!orderReceiptMakePVO.isPreparedForExecution())
    {
      // 1�s���Ȃ��ꍇ�A��s�쐬
      orderReceiptMakePVO.setMaxFetchSize(0);
      orderReceiptMakePVO.executeQuery();
      orderReceiptMakePVO.insertRow(orderReceiptMakePVO.createRow());
    }

    // 1�s�ڂ��擾
    OARow orderReceiptMakePVORow = (OARow)orderReceiptMakePVO.first();

    // �L�[�l���Z�b�g
    orderReceiptMakePVORow.setAttribute("RowKey", new Number(1));
    // �N���������Z�b�g
    orderReceiptMakePVORow.setAttribute("pStartCondition", (String)searchParams.get("startCondition"));
    // �����ԍ����Z�b�g
    orderReceiptMakePVORow.setAttribute("pHeaderNumber",   (String)searchParams.get("headerNumber"));
    // ���הԍ����Z�b�g
    orderReceiptMakePVORow.setAttribute("pLineNumber",     (String)searchParams.get("lineNumber"));


    // ************************************** //
    // * �����������:��������VO ��s�擾   * //
    // ************************************** //
    XxpoOrderDetailsVOImpl orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = null;

    // �������{
    orderDetailsVO.initQuery(searchParams);

    // �f�[�^���擾�ł��Ȃ��ꍇ�A�G���[�y�[�W�֑J�ڂ���
    if (orderDetailsVO.getRowCount() == 0)
    {
      orderReceiptMakePVORow.setAttribute("ApplyReadOnly", Boolean.TRUE);

      // ************************ //
      // * �G���[���b�Z�[�W�o�� * //
      // ************************ //
      throw new OAException(
                  XxcmnConstants.APPL_XXCMN,
                  XxcmnConstants.XXCMN10500,
                  null,
                  OAException.ERROR,
                  null);
    }

    orderDetailsVORow = (OARow)orderDetailsVO.first();


    // ************************************** //
    // * �����������:�������VO ��s�擾   * //
    // ************************************** //
    XxpoReceiptDetailsVOImpl receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // �������{
    receiptDetailsVO.initQuery(searchParams);

    // ***************************************** //
    // * �����������:�������VO ��s�ǉ�      * //
    // ***************************************** //
    // ����.���z�m��t���O���擾
    String moneyDecisionFlag = (String)orderDetailsVORow.getAttribute("MoneyDecisionFlag");

    // ���׋��z�m��t���O��"���z�m���"(Y)�łȂ��ꍇ
    if (!XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
    {

      receiptDetailsVORow = (OARow)receiptDetailsVO.last();

      // �������̏ꍇ
      if (receiptDetailsVORow == null) 
      {
        addRow();

      // �������ȍ~�̏ꍇ
      } else
      {
        // �V�K�쐬���R�[�h�t���O���擾
        Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

        // �[�������擾
        Date deliveryDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

        // �V�K�쐬�Ŗ����ꍇ�A�V�K�s��ǉ�
        if (!(XxcmnUtility.isBlankOrNull(deliveryDate))
          && ((XxcmnUtility.isBlankOrNull(newRowFlag))
          || (!newRowFlag.booleanValue())))
        {
          addRow();

        }

      }
    }

    // ***************************************** //
    // * �����������:�������VO ���͐���      * //
    // ***************************************** //
    if (receiptDetailsVO.getRowCount() > 0) 
    {
    
      // ������ׂ̓��͐�������{
      readOnlyChangedReceiptDetails();
    }
  } // initialize3

  /**************************************************************************
   * (����������͉��)�I���������s�����\�b�h�ł��B
   * @param params �����p�����[�^�pHashMap
   *************************************************************************
   */
  public void doEndOfProcess(
    HashMap params
  ) throws OAException
  {
    HashMap searchParams = new HashMap();
    
    // �����ԍ����Z�b�g
    searchParams.put("headerNumber", params.get("pHeaderNum"));
    // ���הԍ����Z�b�g
    searchParams.put("lineNumber", params.get("pChangedLineNum"));

    XxpoReceiptDetailsVOImpl receiptDetailsVO = getXxpoReceiptDetailsVO1();
    receiptDetailsVO.initQuery(searchParams);  

  }

  /***************************************************************************
   * (����������͉��)������ׂ̓��͐�����s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void readOnlyChangedReceiptDetails() throws OAException
  {

    // �����������:��������VO�擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �����������:�������VO�擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // �����������:�����������PVO�擾
    OAViewObject orderReceiptMakePVO = getXxpoOrderReceiptMakePVO1();
    // 1�s�ڂ��擾
    OARow readOnlyRow = (OARow)orderReceiptMakePVO.first();


    // ************************** //
    // * ������                 * //
    // ************************** //
    readOnlyRow.setAttribute("ApplyReadOnly", Boolean.FALSE);


    // ********************************** //
    // * ���z�m��t���O�ɂ�鍀�ڐ���   * //
    // ********************************** //
    // ����.���z�m��t���O���擾
    String moneyDecisionFlag = (String)orderDetailsVORow.getAttribute("MoneyDecisionFlag");


    // ************************** //
    // * (����)�[�������ڐ���   * //
    // ************************** //
    receiptDetailsVO.first();

    // ���ݍs���擾�ł���ԁA�������J��Ԃ�
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // ������
      receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.FALSE);

      // �V�K�쐬���R�[�h�t���O���擾
      Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

      // �[�������擾
      Date deliveryDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

      // �V�K�쐬�Ŗ����ꍇ�́A���ڐ�������{
      if (!(XxcmnUtility.isBlankOrNull(deliveryDate))
        && ((XxcmnUtility.isBlankOrNull(newRowFlag))
        || (!newRowFlag.booleanValue())))
      {
        receiptDetailsVORow.setAttribute("TxnsDateReadOnly", Boolean.TRUE);
        receiptDetailsVORow.setAttribute("NewRowFlag", Boolean.FALSE);

        // *********************************** //
        // *  �[�����N���[�Y�ɂ�鍀�ڐ���   * //
        // *********************************** //
        // ����.�[�������N���[�Y�̏ꍇ
        if (XxpoUtility.chkStockClose(
              getOADBTransaction(), // �g�����U�N�V����
              deliveryDate))        // ����.�[����
        {

          // ������ׂ̎������/�E�v��ǎ��p�ɕύX
          receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.TRUE);

        }
      }
      
      // *********************************** //
      // *  ���z�m��t���O�ɂ�鍀�ڐ���   * //
      // *********************************** //
      // ���׋��z�m��t���O��"���z�m���"(Y)�̏ꍇ
      if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
      {

        // ������ׂ̎������/�E�v��ǎ��p�ɕύX
        receiptDetailsVORow.setAttribute("ReceiptDetailsReadOnly", Boolean.TRUE);
      }

      receiptDetailsVO.next();
    }


    // ***************************************** //
    // *  ���z�m��t���O�ɂ��K�p�{�^������   * //
    // ***************************************** //
    // ���׋��z�m��t���O��"���z�m���"(Y)�̏ꍇ
    if (XxpoConstants.MONEY_DECISION_FLAG_Y.equals(moneyDecisionFlag))
    {
      // �K�p/�s�}���{�^���𖳌��ɕύX
      readOnlyRow.setAttribute("ApplyReadOnly", Boolean.TRUE);

    }

  } // readOnlyChangedReceiptDetails

  /***************************************************************************
   * (����������͉��)�o�^�E�X�V�O�`�F�b�N�������s���܂��B
   * @return HashMap OA��O���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap dataCheck2() throws OAException
  {
    // OA��O���X�g�𐶐����܂��B
    HashMap messageCode = new HashMap();

    // ************************************ //
    // * ����1:���ʍ��ړ��͒l�`�F�b�N     * //
    // ************************************ //
    messageTextCommonCheck();

    // �������`�F�b�N(true:����, false:��������)
    if (firstTimeCheck())
    {

      // ********************************************* //
      // * ����2�`4:(��)��������\���`�F�b�N       * //
      // ********************************************* //
      reservedQuantityCheck(1, messageCode);

    // ��������
    } else
    {

      // ********************************************* //
      // * ����6-1�`2:(��)��������\���`�F�b�N     * //
      // ********************************************* //
      reservedQuantityCheck(2, messageCode);

    }

    return messageCode;
  } // dataCheck2

  /***************************************************************************
   * (�����������)�o�^�E�X�V�������s���܂��B
   * @return HashMap �o�^�X�V��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap apply2() throws OAException
  {

    // �o�^�X�V��������
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;
    // �O���[�vID
    String[] groupId = null;

    // �������`�F�b�N(true:����, false:��������)
    if (firstTimeCheck())
    {

      // *********************************************** //
      // * ����5-1�`5-2:�������V�K�o�^���O�`�F�b�N * //
      // *********************************************** //
      chkInitialRegistration();

      // *********************************************** //
      // * ����5-3�`5-8:�������o�^����               * //
      // *********************************************** //
      retCode = initialRegistration2();

    // ��������
    } else
    {

      // ********************************************* //
      // * ����6-3�`6-7:�����f�[�^�o�^����           * //
      // ********************************************* //
      retHashMap = correctDataRegistration();
      retCode = (String)retHashMap.get("RetFlag");

    }

    // �o�^�����X�V���ʂ�����łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    // ********************************************** //
    // * ����5-7,7:�����X�e�[�^�X�ύX����           * //
    // ********************************************** //
    chgStatus2();

    // ��L�܂ł̓o�^�X�V����������I��

    // �V�K�s�t���O��������
    chgNewRowFlag();

    // �S�Ă̏���������ɏI�����Ă���ꍇ
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);
    return retHashMap;

  } // apply2

  /***************************************************************************
   * (����������͉��)���ʍ��ړ��͒l�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextCommonCheck() throws OAException
  {

    // OA��O���X�g�𐶐����܂��B
    ArrayList exceptions = new ArrayList(100);
    
    // ********************************** //
    // * ����1:���͍��ڃ`�F�b�N�����{   * //
    // *   1-1:�K�{���ړ��̓`�F�b�N     * //
    // *   1-2:������ʓ��͒l�`�F�b�N   * //
    // *   1-3:�[�����N���[�Y�`�F�b�N   * //
    // ********************************** //
    messageTextInputCheck(exceptions);

    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);
    }

  } // messageTextCommonCheck

  /***************************************************************************
   * (����������͉��)���ړ��͒l�`�F�b�N���s�����\�b�h�ł��B
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextInputCheck(
    ArrayList exceptions
  ) throws OAException
  {
    // �����������:�������VO�擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // 1�s��
    receiptDetailsVO.first();

    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // �s�P�ʂł̕K�{���ړ��̓`�F�b�N�����{
      messageTextInputRowCheck(receiptDetailsVO,
                               receiptDetailsVORow,
                               exceptions);

      receiptDetailsVO.next();

    }

  } // messageTextInputCheck

  /***************************************************************************
   * (����������͉��)�s�P�ʂŕK�{���ړ��̓`�F�b�N���s�����\�b�h�ł��B
   * @param checkVo �`�F�b�N�Ώ�VO
   * @param checkRow �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextInputRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // ������ReadOnly�t���O���擾
    Boolean receiptDetailsReadOnly = (Boolean)checkRow.getAttribute("ReceiptDetailsReadOnly");

    // ������ʂ��擾
    String rcvRtnQuantity = (String)checkRow.getAttribute("RcvRtnQuantity");
    
    // �[�������擾
    Date txnsDate         = (Date)checkRow.getAttribute("TxnsDate");
    
    // �X�V�t���O���擾
    Boolean newRowFlag    = (Boolean)checkRow.getAttribute("NewRowFlag");


    // ************************************ //
    // * ����1-1:�K�{���ړ��̓`�F�b�N     * //
    // ************************************ //
    // ������ʂ��ҏW�\�ȏꍇ�A��������`�F�b�N
    if (!receiptDetailsReadOnly.booleanValue())
    {
    
      // ������ʂ������͂̏ꍇ�̓G���[
      if (XxcmnUtility.isBlankOrNull(rcvRtnQuantity))
      {

        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_RCV_RTN_QUANTITYT);

        // �G���[���b�Z�[�W��ǉ�
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "RcvRtnQuantity",
                              rcvRtnQuantity,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10096,
                              tokens));

      } else
      {

        // ************************************ //
        // * ����1-2:������ʓ��͒l�`�F�b�N   * //
        // ************************************ //
        // �s�P�ʂł̎�����ʓ��͒l�`�F�b�N�����{
        messageTextQuantityRowCheck(checkVo,
                                    checkRow,
                                    exceptions);
      }
    }


    // �[�������ҏW�\�ȏꍇ�A�[�����`�F�b�N
    if (newRowFlag.booleanValue())
    {
      // �[�����������͂̏ꍇ�̓G���[
      if (XxcmnUtility.isBlankOrNull(txnsDate))
      {
        // �G���[���b�Z�[�W�g�[�N���擾
        MessageToken[] tokens = new MessageToken[1];
        tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY, XxpoConstants.TOKEN_NAME_TXNS_DATE);
        
        // �G���[���b�Z�[�W��ǉ�
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              checkVo.getName(),
                              checkRow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10096,
                              tokens));

      // �[���������͂���Ă���ꍇ
      } else
      {

        // ************************************ //
        // * ����1-3:�[�����N���[�Y�`�F�b�N   * //
        // ************************************ //
        // �[�������[�����N���[�Y�̏ꍇ�̓G���[
        if (XxpoUtility.chkStockClose(
          getOADBTransaction(),
          txnsDate))
        {
          // �G���[���b�Z�[�W��ǉ�
          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "TxnsDate",
                                txnsDate,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10140));
        }
      }
    }
  } // messageTextInputRowCheck

  /***************************************************************************
   * (����������͉��)�s�P�ʂŎ�����ʓ��͒l�`�F�b�N���s�����\�b�h�ł��B
   * @param checkVo �`�F�b�N�Ώ�VO
   * @param checkRow �`�F�b�N�Ώۍs
   * @param exceptions �G���[���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void messageTextQuantityRowCheck(
    OAViewObject checkVo,
    OARow checkRow,
    ArrayList exceptions
  ) throws OAException
  {

    // ������ReadOnly�t���O��
    Boolean receiptDetailsReadOnly = (Boolean)checkRow.getAttribute("ReceiptDetailsReadOnly");

    // ������ʂ��擾
    String rcvRtnQuantity = (String)checkRow.getAttribute("RcvRtnQuantity");

    // �[�������擾
    Date txnsDate         = (Date)checkRow.getAttribute("TxnsDate");

    // �X�V�t���O���擾
    Boolean newRowFlag    = (Boolean)checkRow.getAttribute("NewRowFlag");

    // ************************************ //
    // * ����1-2:������ʓ��͒l�`�F�b�N   * //
    // ************************************ //
    // ������ʂ��ҏW�\�ȏꍇ�A��������`�F�b�N
    if (!receiptDetailsReadOnly.booleanValue())
    {
      // ������ʂ�0�����̏ꍇ�̓G���[
      if (!XxcmnUtility.isBlankOrNull(rcvRtnQuantity))
      {
        // ���l�łȂ��ꍇ�̓G���[
        if (!XxcmnUtility.chkNumeric(XxcmnUtility.commaRemoval(rcvRtnQuantity), 9, 3))
        {

          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "RcvRtnQuantity",
                                rcvRtnQuantity,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10001));

        // 0�ȉ��̓G���[
        } else if(!XxcmnUtility.chkCompareNumeric(2, XxcmnUtility.commaRemoval(rcvRtnQuantity), "0"))
        {
          // �G���[���b�Z�[�W�g�[�N���擾
          MessageToken[] tokens = new MessageToken[1];
          tokens[0] = new MessageToken(XxpoConstants.TOKEN_ENTRY,
                                       XxpoConstants.TOKEN_NAME_RCV_RTN_QUANTITYT);

          exceptions.add( new OAAttrValException(
                                OAAttrValException.TYP_VIEW_OBJECT,
                                checkVo.getName(),
                                checkRow.getKey(),
                                "RcvRtnQuantity",
                                rcvRtnQuantity,
                                XxcmnConstants.APPL_XXPO,
                                XxpoConstants.XXPO10068,
                                tokens));

        }
      }
    }
  } // messageTextQuantityRowCheck

  /***************************************************************************
   * (����������͉��)�������ł��邩�`�F�b�N���s�����\�b�h�ł��B
   * @return boolean true:����Afalse:����
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean firstTimeCheck() throws OAException
  {
    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = (OARow)receiptDetailsVO.first();

    // �V�K�s�t���O���擾
    Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

    // �������VO��1�s�ڂ��ێ�����V�K�s�t���O���V�K(true)�̏ꍇ
    if (!(XxcmnUtility.isBlankOrNull(newRowFlag))
      && (newRowFlag.booleanValue()))
    {
      return true;
    }

    return false;

  } // firstTimeCheck
  
  /***************************************************************************
   * (����������͉��)��������\���`�F�b�N���s�����\�b�h�ł��B
   * @param sw �`�F�b�N�؂�ւ��X�C�b�`(1:����A2:����)
   * @param messageCode �G���[�R�[�h���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void reservedQuantityCheck(
    int sw,
    HashMap messageCode
  ) throws OAException
  {

    // ********************************** //
    // * �������׏����擾             * //
    // ********************************** //
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������ׂɕR�t��OPM�i��ID���擾
    Number opmItemId       = (Number)orderDetailsVORow.getAttribute("OpmItemId");

    // �������ׂɕR�t���[����R�[�h���擾
    String locationCode    = (String)orderDetailsVORow.getAttribute("LocationCode");

    // �������ׂɕR�t��LotId���擾
    Number lotId           = (Number)orderDetailsVORow.getAttribute("LotId");

    // �������ׂɕR�t��VendorStockWhse���擾
    String vendorStockWhse = (String)orderDetailsVORow.getAttribute("VendorStockWhse");


    // ************************************* //
    // * ������׏����擾                * //
    // ************************************* //
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow     = (OARow)receiptDetailsVO.first();


    // ************************************* //
    // * �����\���ʂ��擾                * //
    // *   paramsRet(0) : �L���������\�� * //
    // *   paramsRet(1) : �������\��     * //
    // ************************************* //
    HashMap paramsRet = XxpoUtility.getReservedQuantity(
                                      getOADBTransaction(),
                                      opmItemId,            // OPM�i��ID
                                      locationCode,         // �[����R�[�h
                                      lotId);               // ���b�gID


    // ************************************* //
    // * (�����q��)�����\���ʂ��擾    * //
    // *   paramsRet(0) : �L���������\�� * //
    // *   paramsRet(1) : �������\��     * //
    // ************************************* //
    HashMap paramsRet2 = new HashMap();

    // ���Y���я����^�C�v���擾
    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");

    // ���Y���я����^�C�v�������݌�(1)�̏ꍇ
    if (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType))
    {

      paramsRet2 = XxpoUtility.getReservedQuantity(
                                 getOADBTransaction(),
                                 opmItemId,            // OPM�i��ID
                                 vendorStockWhse,      // �����݌ɓ��ɐ�
                                 lotId);               // ���b�gID

    }

    // sw�������������̏ꍇ
    if (sw == 1)
    {

      // (��)��������\���`�F�b�N
      firstTimeReservedQtyCheck(paramsRet, paramsRet2, messageCode);

    // sw��������������̏ꍇ
    } else
    {

      // (��)��������\���`�F�b�N
      correctReservedQtyCheck(paramsRet, paramsRet2, messageCode);

    }
 
  } // reservedQuantityCheck

  /***************************************************************************
   * (����������͉��)�����\���`�F�b�N���s�����\�b�h�ł��B(������)
   * @param reservedQuantity �����\��(�L���������\���A�������\��)
   * @param reservedQuantity2 �����q�Ɉ����\��(�L���������\���A�������\��)
   * @param messageCode �G���[�R�[�h���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void firstTimeReservedQtyCheck(
    HashMap reservedQuantity,
    HashMap reservedQuantity2,
    HashMap messageCode
  ) throws OAException
  {

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;


    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String itemAmount = XxcmnUtility.commaRemoval(
                          (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * �������ʂ��擾                   * //
    // ************************************ //
    String sOrderAmount = XxcmnUtility.commaRemoval(
                            (String)orderDetailsVORow.getAttribute("OrderAmount"));

    // ���Z���K�v�ȏꍇ�́A�݌ɓ����ŏ�Z
    if (conversionFlag)
    {
      double dOrderAmount = Double.parseDouble(sOrderAmount) * Double.parseDouble(itemAmount);
      sOrderAmount = Double.toString(dOrderAmount);
    }


    // ************************************ //
    // * ���.�������(���v)���擾        * //
    // ************************************ //
    double rcvRtnQtyTotal = 0.000;

    // �[�����ߋ����t�`�F�b�N�t���O
    boolean dateOfPastFlag = false;

    // �[���\���
    Date DeliveryDate = (Date)orderDetailsVORow.getAttribute("DeliveryDate");

    // �������.�[����
    Date txnsDate = null;

    receiptDetailsVO.first();

    // ������׍s���擾�ł���ԁA�������J��Ԃ�
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();
      String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      if (!XxcmnUtility.isBlankOrNull(sRcvRtnQty))
      {
        // �J���}�y�я����_������
        sRcvRtnQty = XxcmnUtility.commaRemoval(sRcvRtnQty);

        // �J���}�y�я����_�����������l�����Z
        rcvRtnQtyTotal += Double.parseDouble(sRcvRtnQty);
        
      }

      txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");
      
      // �[�������ߋ����t�̏ꍇ(�[���� > �[���\���)
      if (XxcmnUtility.chkCompareDate(1, txnsDate, DeliveryDate))
      {
        // �ߋ����t�̖��ׂ����݂���
        dateOfPastFlag = true;
      }

      receiptDetailsVO.next();

    }

    // ���Z���K�v�ȏꍇ�́A�݌ɓ����ŏ�Z
    if (conversionFlag)
    {
      rcvRtnQtyTotal = rcvRtnQtyTotal * Double.parseDouble(itemAmount);
    }


    // �L�����x�[�X�����\��
    Object inTimeQty = reservedQuantity.get("InTimeQty");
    // �������\��
    Object totalQty  = reservedQuantity.get("TotalQty");


    // ************************************ //
    // * ����2:�����|���`�F�b�N         * //
    // ************************************ //
    // �ߋ����t�̖��ׂ����݂���ꍇ
    if (dateOfPastFlag)
    {
      // �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
      if ((XxcmnUtility.chkCompareNumeric(1, sOrderAmount, inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, totalQty.toString())))
      {

        // �������|���̊m�F(�x��)
        // ���b�Z�[�W�R�[�h��ݒ�
        messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);

      }
    }


    // ************************************ //
    // * ����3:��������v��`�F�b�N       * //
    // ************************************ //
    // ������ʂ��������ʂ������ꍇ
    if (XxcmnUtility.chkCompareNumeric(1, sOrderAmount, Double.toString(rcvRtnQtyTotal)))
    {
      // �������� = (���v)�������� - (���.���v)�������
      double subtracterAmount = Double.parseDouble(sOrderAmount) - rcvRtnQtyTotal;

      //  �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
      if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(subtracterAmount), inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, Double.toString(subtracterAmount), totalQty.toString())))
      {

        // ��������v��ɂ�鋟���s�̊m�F(�x��)
        // ����2�ɂ����āAXXCMN10112���ݒ肳��Ă��Ȃ��ꍇ
        if (messageCode.size() == 0)
        {
          // ���b�Z�[�W�R�[�h��ݒ�
          messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);
        }

      }
    }


    // ************************************ //
    // * ����4:��������v��`�F�b�N       * //
    // ************************************ //
    // ���Y���я����^�C�v���擾
    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");
    
    // ������ʂ��������ʂ����銎�A���Y���я����^�C�v�������݌�(1)�̏ꍇ
    if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(rcvRtnQtyTotal), sOrderAmount))
      && (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)))
    {
      // �������� = (���.���v)������� - (���v)��������
      double masAmount = rcvRtnQtyTotal - Double.parseDouble(sOrderAmount);

      // (�����݌ɓ��ɐ�)�L�����x�[�X�����\��
      Object inTimeQty2 = reservedQuantity2.get("InTimeQty");
      // (�����݌ɓ��ɐ�)�������\��
      Object totalQty2  = reservedQuantity2.get("TotalQty");

      //  �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
      if ((XxcmnUtility.chkCompareNumeric(1, Double.toString(masAmount), inTimeQty2.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, Double.toString(masAmount), totalQty2.toString())))
      {

        // ��������v��ɂ�鑊���݌ɂ̈����s�̊m�F(�x��)
        // ���b�Z�[�W�R�[�h��ݒ�
        messageCode.put(XxcmnConstants.XXCMN10110, XxcmnConstants.XXCMN10110);

      }
    }
  } // firstTimeReservedQtyCheck

  /***************************************************************************
   * (����������͉��)�����\���`�F�b�N���s�����\�b�h�ł��B(����)
   * @param reservedQuantity �����\��(�L���������\���A�������\��)
   * @param reservedQuantity2 �����q�Ɉ����\��(�L���������\���A�������\��)
   * @param messageCode �G���[�R�[�h���X�g
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void correctReservedQtyCheck(
    HashMap reservedQuantity,
    HashMap reservedQuantity2,
    HashMap messageCode
  ) throws OAException
  {

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;


    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String itemAmount = XxcmnUtility.commaRemoval(
                          (String)orderDetailsVORow.getAttribute("ItemAmount"));


    // ************************************ //
    // * (����)���.�������(���v)���擾  * //
    // * �����O�������(���v)���擾       * //
    // ************************************ //
    double rcvRtnQtyTotal = 0.000;
    double quantityTotal  = 0.000;
    
    receiptDetailsVO.first();

    // ������׍s���擾�ł���ԁA�������J��Ԃ�
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // �������
      String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      // �����O�������
      Number nQuantity    = (Number)receiptDetailsVORow.getAttribute("Quantity");

      // ���.������ʂ̑��v���Z�o
      if (!XxcmnUtility.isBlankOrNull(sRcvRtnQty))
      {
        // �J���}�y�я����_������
        sRcvRtnQty = XxcmnUtility.commaRemoval(sRcvRtnQty);

        // �J���}�y�я����_�����������l�����Z
        rcvRtnQtyTotal += Double.parseDouble(sRcvRtnQty);

      }

      // �����O������ʂ̑��v���Z�o
      if (!XxcmnUtility.isBlankOrNull(nQuantity))
      {
        quantityTotal += Double.parseDouble(XxcmnUtility.stringValue(nQuantity));
      }

      receiptDetailsVO.next();
    }

    // ���Z���K�v�ȏꍇ�́A�݌ɓ����ŏ�Z
    if (conversionFlag)
    {
      rcvRtnQtyTotal = rcvRtnQtyTotal * Double.parseDouble(itemAmount);

      quantityTotal  = quantityTotal  * Double.parseDouble(itemAmount);
    }

    // �L�����x�[�X�����\��
    Object inTimeQty = reservedQuantity.get("InTimeQty");

    // �������\��
    Object totalQty  = reservedQuantity.get("TotalQty");

    // ************************************ //
    // * ����6-1:���������`�F�b�N         * //
    // ************************************ //
    // ������ʂ������O���ʂ������ꍇ
    BigDecimal bQuantityTotal = new BigDecimal(String.valueOf(quantityTotal));
    BigDecimal bRcvRtnQtyTotal = new BigDecimal(String.valueOf(rcvRtnQtyTotal));

    if (XxcmnUtility.chkCompareNumeric(1, bQuantityTotal, bRcvRtnQtyTotal))
    {

      // �������� = (���v)�����O���� - (���.���v)������������
      double subtracterAmount = quantityTotal - rcvRtnQtyTotal;

      // �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
      BigDecimal bSubtracterAmount = new BigDecimal(String.valueOf(subtracterAmount));
      
      if ((XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, inTimeQty.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, bSubtracterAmount, totalQty.toString())))
      {

        // ���������ɂ�鋟���s�̊m�F(�x��)
        // ����2�ɂ����āAXXCMN10112���ݒ肳��Ă��Ȃ��ꍇ
        if (messageCode.size() == 0)
        {
          // ���b�Z�[�W�R�[�h��ݒ�
          messageCode.put(XxcmnConstants.XXCMN10112, XxcmnConstants.XXCMN10112);
        }

      }
    }

    // ************************************ //
    // * ����6-2:���������`�F�b�N         * //
    // ************************************ //
    // ���Y���я����^�C�v���擾
    String productResultType = (String)orderDetailsVORow.getAttribute("ProductResultType");

    // ������ʂ������O������ʂ����銎�A���Y���я����^�C�v�������݌�(1)�̏ꍇ
    if ((XxcmnUtility.chkCompareNumeric(1, bRcvRtnQtyTotal, bQuantityTotal))
      && (XxpoConstants.PRODUCT_RESULT_TYPE_I.equals(productResultType)))
    {
      // �������� = (���.���v)������� - (���v)�����O�������
      double masAmount = rcvRtnQtyTotal- quantityTotal;

      // (�����݌ɓ��ɐ�)�L�����x�[�X�����\��
      Object inTimeQty2 = reservedQuantity2.get("InTimeQty");

      // (�����݌ɓ��ɐ�)�������\��
      Object totalQty2  = reservedQuantity2.get("TotalQty");

      // �w�������� > �L�����x�[�X�����\���x�܂��́A�w�������� > �������\���x
      BigDecimal bMasAmount = new BigDecimal(String.valueOf(masAmount));
      if ((XxcmnUtility.chkCompareNumeric(1, bMasAmount, inTimeQty2.toString()))
        || (XxcmnUtility.chkCompareNumeric(1, bMasAmount, totalQty2.toString())))
      {

        // ���������ɂ�鑊���݌ɂ̈����s�̊m�F(�x��)
        // ���b�Z�[�W�R�[�h��ݒ�
        messageCode.put(XxcmnConstants.XXCMN10110, XxcmnConstants.XXCMN10110);

      }
    }
  } // correctReservedQtyCheck

  /***************************************************************************
   * (����������͉��)�V�K�o�^���O�`�F�b�N���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkInitialRegistration() throws OAException
  {
    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �[���\������擾
    Date deliveryDate = (Date)orderDetailsVORow.getAttribute("DeliveryDate");
    String subStrDeliveryDate = deliveryDate.toString().substring(0,7);

    // �V�X�e�����t���擾
    Date sysDate = XxpoUtility.getSysdate(getOADBTransaction());

// 20080523 del yoshimoto Start
/*
    // ************************************ //
    // * ����5-1:�������t�`�F�b�N         * //
    // ************************************ //
    // �[���\������������łȂ����m�F
    if (XxcmnUtility.chkCompareDate(1, deliveryDate, sysDate))
    {
      // �G���[���b�Z�[�W�o��
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10088);
    }
*/
// 20080523 del yoshimoto End

    // ************************************ //
    // * ����5-1:�������t�`�F�b�N         * //
    // * ����5-2:����N���`�F�b�N         * //
    // ************************************ //
    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    receiptDetailsVO.first();

    ArrayList exceptions = new ArrayList();
    // ������ׂ��擾�ł���ԁA�������p��
    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // ������ׂ̔[�������擾
      Date txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");
      String subStrTxnsDate = txnsDate.toString().substring(0,7);

// 20080523 add yoshimoto Start
      // �[���\������������łȂ����m�F
      if (XxcmnUtility.chkCompareDate(1, txnsDate, sysDate))
      {
        // �G���[���b�Z�[�W�o��
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              receiptDetailsVO.getName(),
                              receiptDetailsVORow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10088));


// 20080523 add yoshimoto End

      // �[�����ƁA�[�����\���������N���Ŗ����ꍇ
      } else if (!subStrDeliveryDate.equals(subStrTxnsDate))
      {
        // �G���[���b�Z�[�W�o��
        exceptions.add( new OAAttrValException(
                              OAAttrValException.TYP_VIEW_OBJECT,
                              receiptDetailsVO.getName(),
                              receiptDetailsVORow.getKey(),
                              "TxnsDate",
                              txnsDate,
                              XxcmnConstants.APPL_XXPO,
                              XxpoConstants.XXPO10061));

      }

      receiptDetailsVO.next();
    }

    // ��O���������ꍇ�A��O���b�Z�[�W���o�͂��A�����I��
    if (exceptions.size() > 0)
    {
      OAException.raiseBundledOAException(exceptions);

    }

  } // chkInitialRegistration

  /***************************************************************************
   * (����������͉��)�V�K�o�^���s�����\�b�h�ł��B
   * @return String �o�^��������(����:�O���[�vID�A���s:xcmnConstants.RETURN_NOT_EXE)
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String initialRegistration2() throws OAException
  {
    // �o�^��������
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // ���v�������
    double receiptAmountTotal = 0.000;

    // ���ID
    Number txnsId = null;

    // �O���[�vID
    Number groupId = null;
    String retGroupId = null;

    receiptDetailsVO.first();

    // ������ׂ��擾�ł���ԁA�������p��
    while(receiptDetailsVO.getCurrentRow() != null)
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();


      // ********************************************** //
      // * ����5-4:����ԕi����(�A�h�I��)�o�^����     * //
      // ********************************************** //
      retHashMap = (HashMap)insRcvAndRtnTxns2(
                              orderDetailsVORow,
                              receiptDetailsVORow);

      retCode = (String)retHashMap.get("RetFlag");

      // �o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        return XxcmnConstants.RETURN_NOT_EXE;
      }

      // ����ԕi����(�A�h�I��).���ID���擾
      txnsId = (Number)retHashMap.get("TxnsId");

      // ������ʂ��擾
      String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

      // �J���}������
      rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);

      receiptAmountTotal += Double.parseDouble(rcvRtnQuantity);


      // ������ʂ�0��葽���ꍇ
      if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
      {
        // ************************************************ //
        // * ����5-3:����I�[�v���C���^�t�F�[�X�o�^����   * //
        // ************************************************ //
        retHashMap = insOpenIf2(
                       orderDetailsVORow,
                       receiptDetailsVORow,
                       txnsId,
                       groupId);

        retCode = (String)retHashMap.get("RetFlag");
        retGroupId = retCode.toString();
        
        // �o�^����������I���łȂ��ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          return XxcmnConstants.RETURN_NOT_EXE;
        }

        // �O���[�vID��ޔ�
        groupId = (Number)retHashMap.get("GroupId");
        retGroupId = groupId.toString();
      }


      // ************************************ //
      // * ����5-8:�݌ɐ���API�N������      * //
      // ************************************ //
      // �����敪���擾
      String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");

      // �����敪�������݌ɂł���ꍇ
      if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
      {
        insIcTranCmp2(XxcmnConstants.STRING_ZERO, // �������[�h(0:������)
                      txnsId,                     // ���ID
                      receiptDetailsVORow);       // �������
      }

      receiptDetailsVO.next();
    }


    // *********************************** //
    // * ����5-5:�������׍X�V����        * //
    // *********************************** //
    // ���b�N�擾����
    getDetailsRowLock((Number)orderDetailsVORow.getAttribute("LineId"));

    // �r������
    chkDetailsExclusiveControl(
      (Number)orderDetailsVORow.getAttribute("LineId"),
      (String)orderDetailsVORow.getAttribute("LastUpdateDate"));

    // �X�V����
    XxpoUtility.updateReceiptAmount(
      getOADBTransaction(),
      (Number)orderDetailsVORow.getAttribute("LineId"),
      receiptAmountTotal);


    // *********************************** //
    // * ����5-6:���b�g�X�V����          * //
    // *********************************** //
    // �i�ڂ����b�g�Ώۂł���ꍇ
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // �X�V����
      updIcLotsMstTxns2();

    }

    // ********************************************** //
    // * ����8:�������������N��                   * //
    // ********************************************** //  
    // ������ʂ�0��葽���ꍇ
    if (!XxcmnUtility.isBlankOrNull(groupId))
    {
      // OIF�o�^�X�V�����̏ꍇ
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      XxpoUtility.doRVCTP(
        getOADBTransaction(),
        retGroupId);
    }
    
    return XxcmnConstants.RETURN_SUCCESS;

  } // initialRegistration2

  /***************************************************************************
   * (����������͉��)�����f�[�^�o�^���s�����\�b�h�ł��B
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap correctDataRegistration() throws OAException
  {

    // �o�^��������
    HashMap retHashMap = new HashMap();
    String retCode = XxcmnConstants.RETURN_NOT_EXE;

    // ���ID
    Number txnsId = null;

    // �O���[�vID
    Number[] groupId = new Number[2];

    // �ԋp�p�O���[�vID
    String[] retGroupId = new String[2];

    // ���v�����O�������
    double quantityTotal      = 0.000;

    // ���v�������
    double receiptAmountTotal = 0.000;

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    receiptDetailsVO.first();

    // ������ׂ��擾�ł���ԁA�������p��
    while(receiptDetailsVO.getCurrentRow() != null)
    {

      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      // �����������ɂ����āA�����O������ʂƎ�����ʂɍ����������ꍇ�́A���������𒆒f
      String chkSubflag = chkSubRcvRtnQuantity(
                                orderDetailsVORow,
                                receiptDetailsVORow);


      // ���ݍs�̎��ID���擾
      txnsId = (Number)receiptDetailsVORow.getAttribute("TxnsId");

      // ������ʂ��擾
      String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
      // �J���}������
      rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
      // ������ʂ����v������ʂɉ��Z
      receiptAmountTotal += Double.parseDouble(rcvRtnQuantity);


      // �����O������ʂ��擾
      Number quantity = (Number)receiptDetailsVORow.getAttribute("Quantity");
      // �����O������ʂ����v�����O������ʂɉ��Z
      if (!XxcmnUtility.isBlankOrNull(quantity))
      {
        quantityTotal += quantity.doubleValue();
        
      }

      // �V�K�쐬���R�[�h�t���O���擾
      Boolean newRowFlag = (Boolean)receiptDetailsVORow.getAttribute("NewRowFlag");

      // �s�}���ɂĒǉ����ꂽ�s�̏ꍇ
      if (newRowFlag.booleanValue())
      {

        // ********************************************** //
        // * ����5-4:����ԕi����(�A�h�I��)�o�^����     * //
        // ********************************************** //
        retHashMap = (HashMap)insRcvAndRtnTxns2(
                                orderDetailsVORow, 
                                receiptDetailsVORow);

        retCode = (String)retHashMap.get("RetFlag");

        // �o�^����������I���łȂ��ꍇ
        if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
        {
          return retHashMap;
        }

        // ����ԕi����(�A�h�I��).���ID���擾
        txnsId = (Number)retHashMap.get("TxnsId");

        // ������ʂ�0��葽���ꍇ
        if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
        {
          // ************************************************ //
          // * ����5-3:����I�[�v���C���^�t�F�[�X�o�^����   * //
          // ************************************************ //
          retHashMap = insOpenIf2(
                         orderDetailsVORow,
                         receiptDetailsVORow,
                         txnsId,
                         groupId[0]);

          retCode = (String)retHashMap.get("RetFlag");
          retGroupId[0] = retCode.toString();
        
          // �o�^����������I���łȂ��ꍇ
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            return retHashMap;
          }

          // �O���[�vID��ޔ�
          groupId[0] = (Number)retHashMap.get("GroupId");
          retGroupId[0] = groupId[0].toString();

        }


        // ************************************ //
        // * ����5-8:�݌ɐ���API�N������      * //
        // ************************************ //
        // �����敪���擾
        String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");

        // �����敪�������݌ɂł���ꍇ
        if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
        {
          insIcTranCmp2(XxcmnConstants.STRING_ZERO, // �������[�h(0:������)
                        txnsId,                     // ���ID
                        receiptDetailsVORow);       // �������
        }

      // �X�V���R�[�h�̏ꍇ
      } else
      {

        // ���ID����ɁA���OIF�ɓo�^�ς݂ł��邩�m�F
        String inputFlag = XxpoUtility.chkRcvOifInput(
                             getOADBTransaction(),
                             txnsId);

        // �����O������ʂƎ�����ʂɍ����������ꍇ�́AOIF�o�^�����͍s��Ȃ�
        if (!"0".equals(chkSubflag)) 
        {
          // ���OIF�ɓo�^�ς݂ł���ꍇ
          if (XxcmnConstants.STRING_Y.equals(inputFlag))
          {

            // ************************************************ //
            // * ����6-3:����I�[�v���C���^�t�F�[�X��������   * //
            // ************************************************ //
            // �������
            String sRcvRtnQty   = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");

            // �����O�������
            Number nQuantity    = (Number)receiptDetailsVORow.getAttribute("Quantity");

            // ��������
            if ("1".equals(chkSubflag))
            {

              // ******************* //
              // * (1) OIF������� * //
              // ******************* //
              retHashMap = correctOpenIf(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              retCode = (String)retHashMap.get("RetFlag");

              // �o�^����������I���łȂ��ꍇ
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // �O���[�vID��ޔ�
              groupId[0] = (Number)retHashMap.get("GroupId");
              
              retGroupId[0] = groupId[0].toString();

              // ******************* //
              // * (2)OIF��������  * //
              // ******************* //
              retHashMap = correctOpenIf2(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[1]);

              retCode = (String)retHashMap.get("RetFlag");

              // �o�^����������I���łȂ��ꍇ
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // �O���[�vID��ޔ�
              groupId[1] = (Number)retHashMap.get("GroupId");
              retGroupId[1] = groupId[1].toString();

            // ��������
            } else 
            {

              // ******************* //
              // * (1)OIF��������  * //
              // ******************* //
              retHashMap = correctOpenIf2(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              
              retCode = (String)retHashMap.get("RetFlag");

              // �o�^����������I���łȂ��ꍇ
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // �O���[�vID��ޔ�
              groupId[0] = (Number)retHashMap.get("GroupId");
              retGroupId[0] = groupId[0].toString();

              // ******************* //
              // * (2) OIF������� * //
              // ******************* //
              retHashMap = correctOpenIf(
                             orderDetailsVORow,
                             receiptDetailsVORow,
                             txnsId,
                             groupId[1]);


              retCode = (String)retHashMap.get("RetFlag");

              // �o�^����������I���łȂ��ꍇ
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // �O���[�vID��ޔ�
              groupId[1] = (Number)retHashMap.get("GroupId");
              retGroupId[1] = groupId[1].toString();
                            
            }

          // ���OIF�ɓo�^�ς݂łȂ��ꍇ
          } else
          {

            // ������ʂ�0��葽���ꍇ
            if (XxcmnUtility.chkCompareNumeric(1, rcvRtnQuantity, "0"))
            {
              // ************************************************ //
              // * ����6-4:����I�[�v���C���^�t�F�[�X�o�^����   * //
              // ************************************************ //
              retHashMap = insOpenIf2(
                             orderDetailsVORow, 
                             receiptDetailsVORow,
                             txnsId,
                             groupId[0]);

              retCode = (String)retHashMap.get("RetFlag");

              // �o�^����������I���łȂ��ꍇ
              if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
              {
                return retHashMap;
              }

              // �O���[�vID��ޔ�
              groupId[0] = (Number)retHashMap.get("GroupId");
              retGroupId[0] = groupId[0].toString();
            }
          }
        }

        // ********************************************** //
        // * ����6-5:����ԕi����(�A�h�I��)�X�V����     * //
        // ********************************************** //
        // ������ʂ��ύX����Ă���A���́A�E�v���ύX����Ă���ꍇ
        if (!"0".equals(chkSubflag) || chkUpdLineDescription(receiptDetailsVORow))
        {
          retCode = updRcvAndRtnTxns(
                      orderDetailsVORow,
                      receiptDetailsVORow);

          // �o�^����������I���łȂ��ꍇ
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
          {
            retHashMap.put("RetFlag", retCode);
            return retHashMap;
          }
        }
      }

      // �����O������ʂƎ�����ʂɍ����������ꍇ�́A�݌ɐ���API�N�������͍s��Ȃ�
      if (!"0".equals(chkSubflag)) 
      {
        // ************************************ //
        // * ����6-7:�݌ɐ���API�N������      * //
        // ************************************ //
        // �����敪���擾
        String orderDivision = (String)orderDetailsVORow.getAttribute("OrderDivision");

        // �����敪�������݌ɂł���ꍇ
        if (XxpoConstants.PO_TYPE_3.equals(orderDivision))
        {
          insIcTranCmp2(XxcmnConstants.STRING_ONE, // �������[�h(1:��������)
                        txnsId,                    // ���ID
                        receiptDetailsVORow);      // �������
        }
      }

      // ********************************************** //
      // * ����8:�������������N��                   * //
      // ********************************************** //
      // OIF�o�^�X�V�����̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(groupId[0]))
      {
        if (XxcmnUtility.isBlankOrNull(groupId[1])) 
        {
       
          retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

          retHashMap = XxpoUtility.doRVCTP(
                         getOADBTransaction(),
                         retGroupId[0]);

          String retFlag = (String)retHashMap.get("RetFlag");
          if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
          {           
            return retHashMap;
          }
          
        // OIF���������̏ꍇ
        } else if (groupId.length > 1)
        {

          for (int i = 0; i < groupId.length; i++) 
          {
            retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

            retHashMap = XxpoUtility.doRVCTP(
                           getOADBTransaction(),
                           retGroupId[i]);

            String retFlag = (String)retHashMap.get("RetFlag");
            if (XxcmnConstants.RETURN_NOT_EXE.equals(retFlag))
            {
              return retHashMap;
            }
          }
        }
      }
      
      receiptDetailsVO.next();

    }

    // *********************************** //
    // * ����6-6:�������׍X�V����        * //
    // *********************************** //
    if (quantityTotal != receiptAmountTotal)
    {

      // ���b�N�擾����
      getDetailsRowLock((Number)orderDetailsVORow.getAttribute("LineId"));

      // �r������
      chkDetailsExclusiveControl(
        (Number)orderDetailsVORow.getAttribute("LineId"),
        (String)orderDetailsVORow.getAttribute("LastUpdateDate"));

      // �X�V����
      XxpoUtility.updateReceiptAmount(
        getOADBTransaction(),
        (Number)orderDetailsVORow.getAttribute("LineId"),
        receiptAmountTotal);

    }

    // ����ɏ������ꂽ�ꍇ�́A�O���[�vID��ԋp
    retHashMap.put("GroupId", retGroupId);
    return retHashMap;

  } // correctDataRegistration


  /***************************************************************************
   * (����������͉��)����ԕi����(�A�h�I��)�o�^�������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insRcvAndRtnTxns2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ���ы敪
    setParams.put("TxnsType",              "1");
    // ����ԕi�ԍ�
    setParams.put("RcvRtnNumber",          orderDetailsVORow.getAttribute("HeaderNumber"));
    // �������ԍ�
    setParams.put("SourceDocumentNumber",  orderDetailsVORow.getAttribute("HeaderNumber"));
    // �����ID
    setParams.put("VendorId",              orderDetailsVORow.getAttribute("VendorId"));
    // �����R�[�h
    setParams.put("VendorCode",            orderDetailsVORow.getAttribute("VendorCode"));
    // ���o�ɐ�R�[�h
    setParams.put("LocationCode",          orderDetailsVORow.getAttribute("LocationCode"));
    // ���������הԍ�
    setParams.put("SourceDocumentLineNum", orderDetailsVORow.getAttribute("LineNum"));
    // ����ԕi���הԍ�
    setParams.put("RcvRtnLineNumber",      receiptDetailsVORow.getAttribute("RcvRtnLineNumber"));
    // �i��ID
    setParams.put("ItemId",                orderDetailsVORow.getAttribute("OpmItemId"));
    // �i�ڃR�[�h
    setParams.put("ItemCode",              orderDetailsVORow.getAttribute("OpmItemNo"));
    // ���b�gID
    setParams.put("LotId",                 orderDetailsVORow.getAttribute("LotId"));
    // ���b�gNo
    setParams.put("LotNumber",             orderDetailsVORow.getAttribute("LotNo"));
    // �����
    setParams.put("TxnsDate",              receiptDetailsVORow.getAttribute("TxnsDate"));

    // ����ԕi����
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval(             // �J���}������
                               (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);   // double�^�֕ϊ�

    setParams.put("RcvRtnQuantity",  new Double(dRcvRtnQuantity).toString());
    // ����ԕi�P��
    setParams.put("RcvRtnUom",       orderDetailsVORow.getAttribute("UnitName"));
    // �P�ʃR�[�h
    setParams.put("Uom",             orderDetailsVORow.getAttribute("UnitMeasLookupCode"));
    // ���דE�v
    setParams.put("LineDescription", receiptDetailsVORow.getAttribute("LineDescription"));
    // �����敪
    setParams.put("DropshipCode",    orderDetailsVORow.getAttribute("DropshipCode"));
    // �P��
    setParams.put("UnitPrice",       orderDetailsVORow.getAttribute("UnitPrice"));
// 20080520 add yoshimoto Start
    // ���������R�[�h
    setParams.put("DepartmentCode",  orderDetailsVORow.getAttribute("DepartmentCode"));
// 20080520 add yoshimoto End

    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ����
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;
      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

      // ���Z�����F���Z�����𔭒�����.�����Ƃ���
      setParams.put("ConversionFactor", sItemAmount);


    // ���Z���s�v�ȏꍇ
    } else
    {

      // ����
      setParams.put("Quantity",         new Double(dRcvRtnQuantity).toString());
      // ���Z�����F���Z������1�Ƃ���
      setParams.put("ConversionFactor", new Integer(1).toString());

    }

    // ************************************ //
    // * ����ԕi����(�A�h�I��)�o�^����   * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvAndRtnTxns

  /***************************************************************************
   * (����������͉��)����ԕi����(�A�h�I��)�����������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @return String �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String updRcvAndRtnTxns(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ���ID
    setParams.put("TxnsId",           receiptDetailsVORow.getAttribute("TxnsId"));
    // ���דE�v
    setParams.put("LineDescription",  receiptDetailsVORow.getAttribute("LineDescription"));

    // ����ԕi����
    String sRcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    sRcvRtnQuantity = XxcmnUtility.commaRemoval(sRcvRtnQuantity);    // �J���}������

    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);    // double�^�֕ϊ�
    setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ����
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {

      // ����
      setParams.put("Quantity", new Double(dRcvRtnQuantity).toString());

    }

    // ************************************ //
    // * ����ԕi����(�A�h�I��)�X�V����   * //
    // ************************************ //
    // ���b�N�̎擾
    getRcvRtnRowLock((Number)receiptDetailsVORow.getAttribute("TxnsId"));

    // �r������
    chkRcvRtnExclusiveControl(
      (Number)receiptDetailsVORow.getAttribute("TxnsId"),
      (String)receiptDetailsVORow.getAttribute("LastUpdateDate"));

    String retCode = XxpoUtility.updateRcvAndRtnTxns(
                                       getOADBTransaction(),
                                       setParams);

    return retCode;

  } // updRcvAndRtnTxns

  /***************************************************************************
   * (����������͉��)OIF�o�^�������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param txnsId ���ID
   * @param groupId �O���[�vID
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insOpenIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;


    // ************************************** //
    // * ����w�b�_OIF�o�^����(�o�^�̂�)    * //
    // ************************************** //
    retHashMap = insRcvHeadersIf(
                   orderDetailsVORow,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");

    // �o�^�E��������������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
      return retHashMap;
    }

    Number headerInterfaceId = (Number)retHashMap.get("HeaderInterfaceId");
    groupId  = (Number)retHashMap.get("GroupId");

    // ************************************** //
    // * ����g�����U�N�V����OIF�o�^����    * //
    // ************************************** //
    retHashMap = insRcvTransactionsIf2(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   headerInterfaceId,
                   groupId);

    retCode = (String)retHashMap.get("RetFlag");
    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    // �o�^����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;

    }


    // �i�ڂ����b�g�Ώۂł���ꍇ
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * �i�ڃ��b�g�g�����U�N�V����OIF�o�^����    * //
      // ******************************************** //
      retCode = insMtlTransactionLotsIf2(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // �o�^����������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // insOpenIf2

  /***************************************************************************
   * (����������͉��)OIF��������������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param txnsId ���ID
   * @param groupId �O���[�vID
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap correctOpenIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * ����g�����U�N�V����OIF��������    * //
    // ************************************** //
    retHashMap = correctRcvTransactionsIf(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   groupId,
                   "0");        // �������(0)�A��������(1)

    groupId = (Number)retHashMap.get("GroupId");

    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    retCode = (String)retHashMap.get("RetFlag");

    // �o�^����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;
      
    }

// 20080513 del yoshimoto Start
/*
    // �i�ڂ����b�g�Ώۂł���ꍇ
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * �i�ڃ��b�g�g�����U�N�V����OIF��������    * //
      // ******************************************** //
      retCode = correctMtlTransactionLotsIf(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // �o�^�E��������������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // ******************************************** //
      // * ������b�g�g�����U�N�V����OIF��������    * //
      // ******************************************** //
      retCode = correctRcvLotsIf(
                  orderDetailsVORow,
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // �o�^�E��������������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }
*/
// 20080513 del yoshimoto End

    retHashMap.put("GroupId", groupId);

    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // correctOpenIf

  /***************************************************************************
   * (����������͉��)OIF���������������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param txnsId ���ID
   * @param groupId �O���[�vID
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap correctOpenIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId
  ) throws OAException
  {

    HashMap retHashMap = new HashMap();
    String retCode = null;

    // ************************************** //
    // * ����g�����U�N�V����OIF��������    * //
    // ************************************** //
    retHashMap = correctRcvTransactionsIf(
                   orderDetailsVORow, 
                   receiptDetailsVORow,
                   txnsId,
                   groupId,
                   "1");       // �������(0)�A��������(1)

    groupId = (Number)retHashMap.get("GroupId");

    Number interfaceTransactionId = (Number)retHashMap.get("InterfaceTransactionId");

    retCode = (String)retHashMap.get("RetFlag");

    // �o�^����������I���łȂ��ꍇ
    if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
    {
      retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);

      return retHashMap;
      
    }

    // �i�ڂ����b�g�Ώۂł���ꍇ
    Number lotCtl = (Number)orderDetailsVORow.getAttribute("LotCtl");
    if (XxcmnUtility.isEquals(lotCtl, XxpoConstants.LOT_CTL_1))
    {

      // ******************************************** //
      // * �i�ڃ��b�g�g�����U�N�V����OIF��������    * //
      // ******************************************** //
      retCode = correctMtlTransactionLotsIf(
                  orderDetailsVORow, 
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // �o�^�E��������������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }

      // ******************************************** //
      // * ������b�g�g�����U�N�V����OIF��������    * //
      // ******************************************** //
      retCode = correctRcvLotsIf(
                  orderDetailsVORow,
                  receiptDetailsVORow,
                  interfaceTransactionId);

      // �o�^�E��������������I���łȂ��ꍇ
      if (XxcmnConstants.RETURN_NOT_EXE.equals(retCode))
      {
        retHashMap.put("RetFlag", XxcmnConstants.RETURN_NOT_EXE);
        return retHashMap;
      }
    }

    retHashMap.put("GroupId", groupId);
    retHashMap.put("RetFlag", XxcmnConstants.RETURN_SUCCESS);

    return retHashMap;
  } // correctOpenIf

  /***************************************************************************
   * (����)����w�b�_OIF�o�^�������s�����\�b�h�ł��B
   * @param row ��������
   * @param groupId �O���[�vID
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insRcvHeadersIf(
    OARow row,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();


    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // �����ԍ�
    setParams.put("HeaderNumber", row.getAttribute("HeaderNumber"));
    // �����w�b�_.�[����
    setParams.put("DeliveryDate", row.getAttribute("DeliveryDate"));
    // �����w�b�_.�d����ID
    setParams.put("VendorId", row.getAttribute("VendorId"));
    // �O���[�vID
    setParams.put("GroupId",  groupId);


    // ************************************ //
    // * ����w�b�_OIF�o�^����            * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvHeadersIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvHeadersIf

  /***************************************************************************
   * (����������͉��)����g�����U�N�V����OIF�o�^�������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param txnsId ���ID
   * @param headerInterfaceId ����w�b�_OIF.header_interface_id
   * @param groupId ����w�b�_OIF.group_id
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap insRcvTransactionsIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number headerInterfaceId,
    Number groupId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // (���)������ʐ��ʂ��擾
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.�[����R�[�h
    setParams.put("LocationCode",       orderDetailsVORow.getAttribute("LocationCode"));
    // ��������ID
    setParams.put("LineId",             orderDetailsVORow.getAttribute("LineId"));
    // ����w�b�_OIF��GROUP_ID�Ɠ��l���w��
    setParams.put("GroupId",            groupId);
    // �[����
    setParams.put("TxnsDate",           receiptDetailsVORow.getAttribute("TxnsDate"));
    // ��������.�i�ڊ�P��
    setParams.put("UnitMeasLookupCode", orderDetailsVORow.getAttribute("UnitMeasLookupCode"));  
    // ��������.�i��ID(ITEM_ID)
    setParams.put("PlaItemId",          orderDetailsVORow.getAttribute("PlaItemId"));
    // �����w�b�_.�����w�b�_ID
    setParams.put("HeaderId",           orderDetailsVORow.getAttribute("HeaderId"));
    // �����w�b�_.�[����
    setParams.put("DeliveryDate",       orderDetailsVORow.getAttribute("DeliveryDate"));
    // ����ԕi����(�A�h�I��)�̎��ID
    setParams.put("TxnsId",             txnsId);
    // ����w�b�_OIF��INTERFACE_TRANSACTION_ID
    setParams.put("HeaderInterfaceId",  headerInterfaceId);


    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ������ʂ�����Ŋ��Z
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }

    // ************************************ //
    // * ����g�����U�N�V����OIF�o�^����  * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.insertRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // insRcvTransactionsIf2

  /***************************************************************************
   * (����������͉��)����g�����U�N�V����OIF�����������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param txnsId ���ID
   * @param groupId ����w�b�_OIF.group_id
   * @param processCode �����敪(0:��������A1:��������)
   * @return HashMap �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap correctRcvTransactionsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number txnsId,
    Number groupId,
    String processCode
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ������ʂ��擾
// 20080526 mod yoshimoto Start
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);
// 20080526 mod yoshimoto End

    // �����O������ʂ��擾
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
    double dQuantity  = Double.parseDouble(quantity.toString());
    

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // IN�p�����[�^�擾   
    // �����w�b�_.�����ԍ�
    setParams.put("HeaderNumber", orderDetailsVORow.getAttribute("HeaderNumber"));
    // �����w�b�_.�����w�b�_ID
    setParams.put("HeaderId",     orderDetailsVORow.getAttribute("HeaderId"));
    // ��������ID
    setParams.put("LineId",       orderDetailsVORow.getAttribute("LineId"));
    // ����ԕi����(�A�h�I��)�̎��ID
    setParams.put("TxnsId",       txnsId);
    // �O���[�vID
    setParams.put("GroupId",      groupId);
    // ���b�g�Ώ�
    setParams.put("LotCtl",       orderDetailsVORow.getAttribute("LotCtl"));
    // �����敪
    setParams.put("ProcessCode",  processCode);


    // ���Z���K�v�ȏꍇ
    if (conversionFlag) 
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������(������)
      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {

      // �������(������)
      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;

      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());

    }

    // ************************************ //
    // * ����g�����U�N�V����OIF��������  * //
    // ************************************ //
    HashMap retHashMap = XxpoUtility.correctRcvTransactionsIf(
                                       getOADBTransaction(),
                                       setParams);

    return retHashMap;

  } // correctRcvTransactionsIf


  /***************************************************************************
   * (����������͉��)�i�ڃ��b�g�g�����U�N�V����OIF�o�^�������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param interfaceTransactionId ����g�����U�N�V����OIF.interface_transaction_id
   * @return String �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String insMtlTransactionLotsIf2(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // ������ʂ��擾
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.���b�gNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // ����w�b�_OIF��INTERFACE_TRANSACTION_ID
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);

    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dRcvRtnQuantity).toString());
    }


    // ******************************************* //
    // * �i�ڃ��b�g�g�����U�N�V����OIF�o�^����   * //
    // ******************************************* //
    String retCode = XxpoUtility.insertMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // insMtlTransactionLotsIf2

  /***************************************************************************
   * (����������͉��)�i�ڃ��b�g�g�����U�N�V����OIF�����������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param interfaceTransactionId ����w�b�_OIF.header_interface_id
   * @return String �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String correctMtlTransactionLotsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // �����O������ʂ��擾
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
    double dQuantity  = Double.parseDouble(quantity.toString());

    // ������ʂ��擾
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.���b�gNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // InterfaceTransactionId
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);
// 20080611 yoshimoto add Start ST�s�#72
    // ��������.OPM�i��ID
    setParams.put("OpmItemId",          orderDetailsVORow.getAttribute("OpmItemId"));
// 20080611 yoshimoto add End ST�s�#72

    // ���Z���K�v�ȏꍇ
    if (conversionFlag) 
    {

      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������(������)
      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {

      // �������(������)
      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;

      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());

    }

    // ******************************************* //
    // * �i�ڃ��b�g�g�����U�N�V����OIF��������   * //
    // ******************************************* //
    String retCode = XxpoUtility.correctMtlTransactionLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // correctMtlTransactionLotsIf

  /***************************************************************************
   * (����������͉��)������b�g�g�����U�N�V����OIF�����������s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @param interfaceTransactionId ����w�b�_OIF.header_interface_id
   * @return String �o�^��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String correctRcvLotsIf(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow,
    Number interfaceTransactionId
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ���Z�������擾
    String sItemAmount = XxcmnUtility.commaRemoval(
                           (String)orderDetailsVORow.getAttribute("ItemAmount"));

    // �����O������ʂ��擾
    Number quantity   =(Number)receiptDetailsVORow.getAttribute("Quantity");
    double dQuantity  = Double.parseDouble(quantity.toString());

    // ������ʂ��擾
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    // ��������.���b�gNo
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));
    // �����w�b�_ID
    setParams.put("HeaderId",           orderDetailsVORow.getAttribute("HeaderId"));
    // ��������ID
    setParams.put("LineId",             orderDetailsVORow.getAttribute("LineId"));
    // ���ID
    setParams.put("TxnsId",             receiptDetailsVORow.getAttribute("TxnsId"));
    // InterfaceTransactionId
    setParams.put("InterfaceTransactionId",  interfaceTransactionId);
// 20080611 yoshimoto add Start ST�s�#72
    // ��������.OPM�i��ID
    setParams.put("OpmItemId",          orderDetailsVORow.getAttribute("OpmItemId"));
// 20080611 yoshimoto add End ST�s�#72

    // ���Z���K�v�ȏꍇ
    if (conversionFlag) 
    {
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������(������)
      double dSubRcvRtnQuantity = (dRcvRtnQuantity * dItemAmount) - dQuantity;

      // �������(���Z����)
      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // �������(������)
      double dSubRcvRtnQuantity = dRcvRtnQuantity - dQuantity;

      setParams.put("RcvRtnQuantity", new Double(dSubRcvRtnQuantity).toString());
    }


    // ******************************************* //
    // * ������b�g�g�����U�N�V����OIF��������   * //
    // ******************************************* //
    String retCode = XxpoUtility.correctRcvLotsIf(
                                   getOADBTransaction(),
                                   setParams);

    return retCode;

  } // correctRcvLotsIf

  /***************************************************************************
   * (����������͉��)OPM���b�gMST�X�V�������s�����\�b�h�ł��B
   * @return String �X�V��������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String updIcLotsMstTxns2()
  throws OAException
  {

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // �������VO���擾
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    OARow receiptDetailsVORow = null;

    // ���b�gNo���擾
    String lotNo     = (String)orderDetailsVORow.getAttribute("LotNo");
    // OPM�i��ID���擾
    Number opmItemId = (Number)orderDetailsVORow.getAttribute("OpmItemId");
    // OPM���b�gMST�ŏI�X�V�����擾
    String lotLastUpdateDate   = (String)orderDetailsVORow.getAttribute("LotLastUpdateDate");
    // OPM���b�gMST.�[����(����)
    Date firstTimeDeliveryDate = (Date)orderDetailsVORow.getAttribute("FirstTimeDeliveryDate");
    // OPM���b�gMST.�[����(�ŏI)
    Date finalDeliveryDate     = (Date)orderDetailsVORow.getAttribute("FinalDeliveryDate");

    HashMap setParams = new HashMap();

    // ************************************************** //
    // * �������(�[������)�ŏ����t�ƍő���t���擾     * //
    // ************************************************** //
    Date minTxnsDate = null; 
    Date maxTxnsDate = null;

    receiptDetailsVO.first();

    // ���׉�擾�ł���ԁA�������p�����āA(�[������)�ŏ����t�ƍő���t����
    while (receiptDetailsVO.getCurrentRow() != null) 
    {
      receiptDetailsVORow = (OARow)receiptDetailsVO.getCurrentRow();

      Date txnsDate = (Date)receiptDetailsVORow.getAttribute("TxnsDate");

      // ������
      if (XxcmnUtility.isBlankOrNull(minTxnsDate))
      {
        minTxnsDate = txnsDate;
      }
      if (XxcmnUtility.isBlankOrNull(maxTxnsDate))
      {
        maxTxnsDate = txnsDate;
      }
      
      // �ŏ����t�Ɣ�r
      if (XxcmnUtility.chkCompareDate(1, minTxnsDate, txnsDate))
      {
        minTxnsDate = txnsDate;
      }

      // �ő���t�Ɣ�r
      if (XxcmnUtility.chkCompareDate(1, txnsDate, maxTxnsDate))
      {
        maxTxnsDate = txnsDate;
      }

      receiptDetailsVO.next();

    }


    // ************************************ //
    // * �p�����[�^��ݒ�                 * //
    // ************************************ //
    setParams.put("LotNo", lotNo);
    setParams.put("ItemId", opmItemId);

    // OPM���b�gMST.�[����(����)���u�����N(Null)�ł���A
    //   �܂��́A���.�������.�[������OPM���b�gMST.�[����(����)���ߋ����̏ꍇ
    if (XxcmnUtility.isBlankOrNull(firstTimeDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, firstTimeDeliveryDate, minTxnsDate))
    {

      setParams.put("FirstTimeDeliveryDate", minTxnsDate.toString());    // �[����(����)

    }

    // OPM���b�gMST.�[����(�ŏI)���u�����N(Null)�ł���A
    //   �܂��́A���.�������.�[������OPM���b�gMST.�[����(�ŏI)��薢�����̏ꍇ
    if (XxcmnUtility.isBlankOrNull(finalDeliveryDate)
      || XxcmnUtility.chkCompareDate(1, maxTxnsDate, finalDeliveryDate))
    {

      setParams.put("FinalDeliveryDate", maxTxnsDate.toString());       // �[����(�ŏI)

    }

    // ���b�N�擾����
    getOpmLotMstRowLock(lotNo,       // ���b�gNo
                        opmItemId);  // OPM�i��ID

    // �r������
    chkOpmLotMstExclusiveControl(lotNo,               // ���b�gNo
                                 opmItemId,           // OPM�i��ID
                                 lotLastUpdateDate);  // �ŏI�X�V��

    // ****************** //
    // * �X�V����       * //
    // ****************** //
    XxpoUtility.updateIcLotsMstTxns2(
      getOADBTransaction(),
      setParams);

    return XxcmnConstants.RETURN_SUCCESS;

  } // updIcLotsMstTxns2

  /***************************************************************************
   * (����������͉��)�݌ɐ���API�N���������s�����\�b�h�ł��B
   * @param sw 0:����o�^�����A1:��������
   * @param txnsId ���ID
   * @param receiptDetailsVORow �������
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void insIcTranCmp2(
    String sw,
    Number txnsId,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    HashMap setParams = new HashMap();

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    setParams.put("LocationCode",       orderDetailsVORow.getAttribute("VendorStockWhse"));    // �ۊǏꏊ(�����݌ɓ��ɐ�)
    setParams.put("ItemNo",             orderDetailsVORow.getAttribute("OpmItemNo"));          // �i��(OPM�i�ږ�)
    setParams.put("UnitMeasLookupCode", orderDetailsVORow.getAttribute("UnitMeasLookupCode")); // �i�ڊ�P��
    setParams.put("LotNo",              orderDetailsVORow.getAttribute("LotNo"));              // ���b�g
    setParams.put("TxnsDate",           receiptDetailsVORow.getAttribute("TxnsDate"));         // �����(�������.�[����)
    setParams.put("ReasonCode",         XxpoConstants.CTPTY_INV_SHIP_RSN);                     // ���R�R�[�h(XXPO_CTPTY_INV_SHIP_RSN)
    setParams.put("TxnsId",             txnsId);                                               // �����\�[�XID(����ԕi����(�A�h�I��).���ID)

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ������ʂ��擾
    String rcvRtnQuantity = (String)receiptDetailsVORow.getAttribute("RcvRtnQuantity");
    rcvRtnQuantity = XxcmnUtility.commaRemoval(rcvRtnQuantity);
    //double dRcvRtnQuantity = Double.parseDouble((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(rcvRtnQuantity);

    // �����O������ʂ��擾
    Number quantity = (Number)receiptDetailsVORow.getAttribute("Quantity");


    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      // ���Z�������擾
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // �������
      // ��������
      if (XxcmnConstants.STRING_ZERO.equals(sw))
      {

        // ������� * ���� * (-1)
        dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount * (-1);

      // ����������
      } else
      {

        // ((������̎������ * ����) - �����O�̎������) * (-1)
        dRcvRtnQuantity = ((dRcvRtnQuantity * dItemAmount) - quantity.doubleValue()) * (-1);

      }

      // �������(���Z����)
      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    // ���Z���s�v�ȏꍇ
    } else
    {
      // ��������
      if (XxcmnConstants.STRING_ZERO.equals(sw))
      {

        // ������� * (-1)
        dRcvRtnQuantity = dRcvRtnQuantity * (-1);

      // ����������
      } else
      {

        // (������̎������ - �����O�̎������) * (-1)
        dRcvRtnQuantity = (dRcvRtnQuantity - quantity.doubleValue()) * (-1);

      }

      setParams.put("Amount", new Double(dRcvRtnQuantity).toString());

    }

    // �݌ɐ���API���N��
    XxpoUtility.insertIcTranCmp(
      getOADBTransaction(),
      setParams);

  } // insIcTranCmp2

  /***************************************************************************
   * (����������͉��)�����w�b�_.�X�e�[�^�X�ύX���s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chgStatus2()
  throws OAException
  {
    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow = (OARow)orderDetailsVO.first();

    // ���݂̃X�e�[�^�X�R�[�h���擾
    String statusCode = (String)orderDetailsVORow.getAttribute("StatusCode");
    // �����w�b�_ID���擾
    Number headerId = (Number)orderDetailsVORow.getAttribute("HeaderId");

    // �����w�b�_�ɕR�t���S�Ă̔������ׂ̐��ʊm��t���O��'Y'�ł��邩���m�F
    String chkAllFinDecisionAmountFlg = XxpoUtility.chkAllFinDecisionAmountFlg(
                                          getOADBTransaction(),
                                          headerId);

    // �����w�b�_�ɕR�t���S�Ă̔������ׂ̐��ʊm��t���O��'Y'�̏ꍇ
    if (XxcmnConstants.STRING_Y.equals(chkAllFinDecisionAmountFlg))
    {

      // ���b�N�擾����
      getHeaderRowLock(headerId);

      // �r������
      chkHdrExclusiveControl(
        headerId,
        (String)orderDetailsVORow.getAttribute("PhaLastUpdateDate"));

      // �X�V����(�X�e�[�^�X�R�[�h�F���ʊm���(20))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_FINISH_DECISION_AMOUNT,  // ���ʊm���(20)
        headerId);                                    // �����w�b�_ID

    // ���݂̃X�e�[�^�X���A�����쐬��(20)�̏ꍇ  
    } else if (XxpoConstants.STATUS_FINISH_ORDERING_MAKING.equals(statusCode)) 
    {

      // ���b�N�擾����
      getHeaderRowLock(headerId);

      // �r������    
      chkHdrExclusiveControl(
        headerId,
        (String)orderDetailsVORow.getAttribute("PhaLastUpdateDate"));

      // �X�V����(�X�e�[�^�X�R�[�h�F�������(15))
      XxpoUtility.updateStatusCode(
        getOADBTransaction(),
        XxpoConstants.STATUS_REPUTATION_CASE, // �������(15)
        headerId);                            // �����w�b�_ID

    }

  } // chgStatus2

  /***************************************************************************
   * (����������͉��)�g�[�N���p�̏����擾���郁�\�b�h�ł��B
   * @param sw 0:�����|��/��������v��A1:��������v��
   * @return HashMap �g�[�N��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public HashMap getToken2(String sw) throws OAException
  {
    // �g�[�N�����i�[
    HashMap tokens = new HashMap();

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();
    OARow orderDetailsVORow     = (OARow)orderDetailsVO.first();

    // �����|��/��������v��
    if (XxcmnConstants.STRING_ZERO.equals(sw))
    {
      // �[���於
      tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderDetailsVORow.getAttribute("LocationName"));

    // ��������v��
    } else
    {
      // �����݌ɓ��ɐ於
      tokens.put(XxcmnConstants.TOKEN_LOCATION, (String)orderDetailsVORow.getAttribute("VendorStockWhseName"));
    }

    // �i�ږ�
    tokens.put(XxcmnConstants.TOKEN_ITEM,     (String)orderDetailsVORow.getAttribute("OpmItemName"));
    // ���b�gNo
    tokens.put(XxcmnConstants.TOKEN_LOT,      (String)orderDetailsVORow.getAttribute("LotNo"));

    return tokens;
  } // getToken2

  /***************************************************************************
   * (����������͉��)�V�K�s�t���O��ύX���郁�\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chgNewRowFlag()
  throws OAException
  {
    OAViewObject receiptDetailsVO = getXxpoReceiptDetailsVO1();
    Row[] rows = receiptDetailsVO.getFilteredRows("NewRowFlag", Boolean.TRUE);

    OARow row = null;
    for (int i = 0; i < rows.length; i++)
    {
      // i�Ԗڂ̍s���擾
      row = (OARow)rows[i];
      row.setAttribute("NewRowFlag", Boolean.FALSE);
    }
  }

  /***************************************************************************
   * (����)�����w�b�_�̃��b�N�������s�����\�b�h�ł��B
   * @param headerId �����w�b�_ID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getHeaderRowLock(
    Number headerId
  ) throws OAException
  {

    String apiName = "getHeaderRowLock";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pha_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pha.po_header_id header_id "); // �w�b�_�[ID
    sb.append("    FROM   po_headers_all pha ");         // �����w�b�_
    sb.append("    WHERE  pha.po_header_id = :1 ");
    sb.append("    FOR UPDATE OF pha.po_header_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pha_cur; ");
    sb.append("  CLOSE pha_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(headerId));

      cstmt.execute();

    } catch (SQLException s)
    {

      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);

      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {

        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getHeaderRowLock

  /***************************************************************************
   * (����)�����w�b�_�[�̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param headerId �����w�b�_ID
   * @param lastUpdateDate �ŏI�X�V��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkHdrExclusiveControl(
    Number headerId,
    String lastUpdateDate
  ) throws OAException
  {

    String apiName  = "chkHdrExclusiveControl";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pha.po_header_id) cnt "); // �����w�b�_ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   po_headers_all pha ");          // �����w�b�_
      sb.append("  WHERE  pha.po_header_id = :2 ");       // �����w�b�_ID
      sb.append("  AND    TO_CHAR(pha.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(headerId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s) 
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally 
    {
      try
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkHdrExclusiveControl

  /***************************************************************************
   * (����)�������ׂ̃��b�N�������s�����\�b�h�ł��B
   * @param lineId ��������ID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getDetailsRowLock(
    Number lineId
  ) throws OAException 
  {

    String apiName = "getDetailsRowLock";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR pla_cur ");
    sb.append("  IS ");
    sb.append("    SELECT pla.po_line_id line_id ");     // �w�b�_�[ID
    sb.append("    FROM   po_lines_all pla ");           // ��������
    sb.append("    WHERE  pla.po_line_id = :1 ");
    sb.append("    FOR UPDATE OF pla.po_line_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  pla_cur; ");
    sb.append("  CLOSE pla_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      cstmt.setInt(1, XxcmnUtility.intValue(lineId));

      cstmt.execute();

    } catch (SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally 
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // getDetailsRowLock

  /***************************************************************************
   * (����)�������ׂ̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param lineId ��������ID
   * @param lastUpdateDate �ŏI�X�V��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkDetailsExclusiveControl(
    Number lineId,
    String lastUpdateDate
  ) throws OAException
  {

    String apiName  = "chkDetailsExclusiveControl";

    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(pla.po_line_id) cnt ");              // �����w�b�_ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   po_lines_all pla ");                       // ��������
      sb.append("  WHERE  pla.po_line_id = TO_NUMBER(:2) ");         // ���׍sID
      sb.append("  AND    TO_CHAR(pla.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);


      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(lineId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN, 
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // chkDetailsExclusiveControl


  /***************************************************************************
   * (����)OPM���b�gMST�̃��b�N�������s�����\�b�h�ł��B
   * @param lotNo ���b�gNo
   * @param itemId OPM�i��ID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getOpmLotMstRowLock(
    String lotNo,
    Number itemId
  ) throws OAException 
  {

    String apiName = "getOpmLotMstRowLock";
    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR lotMst_cur ");
    sb.append("  IS ");
    sb.append("    SELECT ilm.lot_id lot_id ");    // ���b�gID
    sb.append("    FROM   IC_LOTS_MST ilm ");      // OPM���b�gMST
    sb.append("    WHERE  ilm.LOT_NO  = :1 ");
    sb.append("    AND    ilm.ITEM_ID = :2 ");
    sb.append("    FOR UPDATE OF ilm.lot_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  lotMst_cur; ");
    sb.append("  CLOSE lotMst_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);
    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setString(i++, lotNo);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));

      cstmt.execute();

    } catch (SQLException s)
    {
      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO, 
                            XxpoConstants.XXPO10138);
    } finally
    {
      try 
      {
        if (cstmt != null)
        { 
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getOpmLotMstRowLock

  /***************************************************************************
   * (����)OPM���b�gMST�r������`�F�b�N���s�����\�b�h�ł��B
   * @param lotNum ���b�gNo
   * @param itemId OPM�i��ID
   * @param lotLastUpdateDate �ŏI�X�V��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkOpmLotMstExclusiveControl(
    String lotNum,
    Number itemId,
    String lotLastUpdateDate
  ) throws OAException
  {
    String apiName  = "chkOpmLotMstExclusiveControl";

    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(ilm.lot_id) cnt ");       // �i��ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   IC_LOTS_MST ilm ");             // OPM���b�g�}�X�^
      sb.append("  WHERE  ilm.item_id = :2 ");            // �i��ID
      sb.append("  AND    ilm.LOT_NO  = :3 ");            // ���b�gNo
      sb.append("  AND    TO_CHAR(ilm.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :4 "); // �ŏI�X�V��
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(itemId));
      cstmt.setString(i++, lotNum);
      cstmt.setString(i++, lotLastUpdateDate);

      cstmt.execute();

      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {
        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {
      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN, 
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkOpmLotMstExclusiveControl

  /***************************************************************************
   * (����)����ԕi(�A�h�I��)�̃��b�N�������s�����\�b�h�ł��B
   * @param txnsId ���ID
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getRcvRtnRowLock(
    Number txnsId
  ) throws OAException 
  {

    String apiName = "getRcvRtnRowLock";

    // PL/SQL�̍쐬���s���܂�
    StringBuffer sb = new StringBuffer(1000);
    sb.append("DECLARE ");
    sb.append("  CURSOR rart_cur ");
    sb.append("  IS ");
    sb.append("    SELECT rart.txns_id txns_id ");       // ���ID
    sb.append("    FROM   xxpo_rcv_and_rtn_txns rart "); // ����ԕi����(�A�h�I��)
    sb.append("    WHERE  rart.txns_id = :1 ");
    sb.append("    FOR UPDATE OF rart.txns_id NOWAIT; ");
    sb.append("BEGIN ");
    sb.append("  OPEN  rart_cur; ");
    sb.append("  CLOSE rart_cur; ");
    sb.append("END; ");

    //PL/SQL�̐ݒ���s���܂�
    CallableStatement cstmt = getOADBTransaction().createCallableStatement(
                                sb.toString(),
                                OADBTransaction.DEFAULT);

    try
    {

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));

      cstmt.execute();

    } catch (SQLException s)
    {

      // ���[���o�b�N
      XxpoUtility.rollBack(getOADBTransaction());
      
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      // ���b�N�G���[
      throw new OAException(XxcmnConstants.APPL_XXPO,
                            XxpoConstants.XXPO10138);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        // ���[���o�b�N
        XxpoUtility.rollBack(getOADBTransaction());
        
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      } 
    }
  } // getRcvAndRtnTxnsRowLock

  /***************************************************************************
   * (����)����ԕi����(�A�h�I��)�̔r������`�F�b�N���s�����\�b�h�ł��B
   * @param txnsId ���ID
   * @param lastUpdateDate �ŏI�X�V��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void chkRcvRtnExclusiveControl(
    Number txnsId,
    String lastUpdateDate
  )throws OAException 
  {

    String apiName  = "chkRcvRtnExclusiveControl";
    CallableStatement cstmt = null;

    try
    {
      // PL/SQL�̍쐬���s���܂�
      StringBuffer sb = new StringBuffer(1000);
      sb.append("BEGIN ");
      sb.append("  SELECT COUNT(rart.txns_id) cnt ");     // ���ID
      sb.append("  INTO   :1 ");
      sb.append("  FROM   xxpo_rcv_and_rtn_txns rart ");  // ����ԕi����(�A�h�I��)
      sb.append("  WHERE  rart.txns_id = :2 ");           // ���ID
      sb.append("  AND    TO_CHAR(rart.last_update_date, 'YYYY/MM/DD HH24:MI:SS')   = :3 ");
      sb.append("  AND    ROWNUM                 = 1  ");
      sb.append("  ;  ");
      sb.append("END; ");

      //PL/SQL�̐ݒ���s���܂�
      cstmt = getOADBTransaction().createCallableStatement(
                sb.toString(),
                OADBTransaction.DEFAULT);

      //PL/SQL�����s���܂�
      int i = 1;
      cstmt.registerOutParameter(i++, Types.INTEGER);
      cstmt.setInt(i++, XxcmnUtility.intValue(txnsId));
      cstmt.setString(i++, lastUpdateDate);

      cstmt.execute();

      // �r���G���[�̏ꍇ
      if (cstmt.getInt(1) == 0)
      {

        doRollBack();
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10147);
      }

    } catch (SQLException s)
    {

      doRollBack();
      XxcmnUtility.writeLog(getOADBTransaction(),
                            XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                            s.toString(),
                            6);
      throw new OAException(XxcmnConstants.APPL_XXCMN,
                            XxcmnConstants.XXCMN10123);
    } finally
    {
      try
      {
        if (cstmt != null)
        {
          cstmt.close();
        }
      } catch (SQLException s)
      {
        doRollBack();
        XxcmnUtility.writeLog(getOADBTransaction(),
                              XxpoConstants.CLASS_AM_XXPO310001J + XxcmnConstants.DOT + apiName,
                              s.toString(),
                              6);
        throw new OAException(XxcmnConstants.APPL_XXCMN,
                              XxcmnConstants.XXCMN10123);
      }
    }
  } // chkRcvRtnExclusiveControl

  /***************************************************************************
   * (����)OIF�X�V�L���`�F�b�N���s�����\�b�h�ł��B
   * @param orderDetailsVORow ��������
   * @param receiptDetailsVORow �������
   * @return String 1:���������ɂ��X�V�K�v�A0:�X�V�s�v�A-1:���������ɂ��X�V�K�v
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String chkSubRcvRtnQuantity(
    OARow orderDetailsVORow,
    OARow receiptDetailsVORow
  ) throws OAException
  {

    // ************************************ //
    // * ���Z�L���`�F�b�N                 * //
    // ************************************ //
    boolean conversionFlag = false;
    String prodClassCode = (String)orderDetailsVORow.getAttribute("ProdClassCode");
    String itemClassCode = (String)orderDetailsVORow.getAttribute("ItemClassCode");
    String convUnit      = (String)orderDetailsVORow.getAttribute("ConvUnit");

    // ���Z�L���`�F�b�N�����{
    conversionFlag = chkConversion(
                       prodClassCode,  // ���i�敪
                       itemClassCode,  // �i�ڋ敪
                       convUnit);      // ���o�Ɋ��Z�P��

    // ������ʂ��擾
    String sRcvRtnQuantity = XxcmnUtility.commaRemoval((String)receiptDetailsVORow.getAttribute("RcvRtnQuantity"));
    double dRcvRtnQuantity = Double.parseDouble(sRcvRtnQuantity);
    // �����O������ʂ��擾
    Number quantity  = (Number)receiptDetailsVORow.getAttribute("Quantity");
    double dQuantity = XxcmnUtility.doubleValue(quantity);


    // ���Z���K�v�ȏꍇ
    if (conversionFlag)
    {
      // ���Z�������擾
      String sItemAmount = XxcmnUtility.commaRemoval(
                             (String)orderDetailsVORow.getAttribute("ItemAmount"));
      double dItemAmount = Double.parseDouble(sItemAmount); // ����

      // ������� * ����
      dRcvRtnQuantity = dRcvRtnQuantity * dItemAmount;

    }

    if (dQuantity == dRcvRtnQuantity)
    {

      return "0";

    } else if (dQuantity > dRcvRtnQuantity)
    {

      return "-1";

    } else
    {
    
      return "1";
      
    }

  } // chkSubRcvRtnQuantity

  /***************************************************************************
   * (����)�E�v�X�V�L���`�F�b�N���s�����\�b�h�ł��B
   * @param receiptDetailsVORow �������
   * @return true:�X�V�K�v�Afalse:�X�V�s�v
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean chkUpdLineDescription(
    OARow receiptDetailsVORow
  ) throws OAException
  {

    // �X�V�O�E�v���擾
    String baseLineDescription = (String)receiptDetailsVORow.getAttribute("BaseLineDescription");

    // ���.�E�v���擾
    String lineDescription = (String)receiptDetailsVORow.getAttribute("LineDescription");

    // �����ڂƂ��u�����N�̏ꍇ�́A�X�V�s�v
    if (XxcmnUtility.isBlankOrNull(baseLineDescription)
      && XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return false;
    }

    // �Е��̂݃u�����N�̏ꍇ�́A�X�V�K�v
    if (!XxcmnUtility.isBlankOrNull(baseLineDescription)
      && XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return true;
    }

    if (XxcmnUtility.isBlankOrNull(baseLineDescription)
      && !XxcmnUtility.isBlankOrNull(lineDescription))
    {
      return true;
    }

    // �������͍ς݂ł���ꍇ�́A��r
    if (!baseLineDescription.equals(lineDescription))
    {
      return true;
    }

    return false;

  } // chkUpdLineDescription

  /***************************************************************************
   * (����)���Z�L���`�F�b�N���s�����\�b�h�ł��B
   * @param prodClassCode ���i�敪
   * @param itemClassCode �i�ڋ敪
   * @param convUnit ���o�Ɋ��Z�P��
   * @return true:���Z�K�v�Afalse:���Z�s�v
   * @throws OAException OA��O
   ***************************************************************************
   */
  public boolean chkConversion(
    String prodClassCode,
    String itemClassCode,
    String convUnit
  ) throws OAException
  {

    // ���i�敪2(�h�����N)���A�i�ڋ敪5(���i)���A���o�Ɋ��Z�P�ʂ��u�����N�ȊO�̏ꍇ
    if ((XxpoConstants.PROD_CLASS_DRINK.equals(prodClassCode))
      && (XxpoConstants.ITEM_CLASS_PROD.equals(itemClassCode))
      && !(XxcmnUtility.isBlankOrNull(convUnit)))
    {

      // ���Z���K�v
      return true;

    }

    // ���Z�͕s�v
    return false;

  } // chkConversion

  /***************************************************************************
   * (����)�R�~�b�g�������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doCommit() throws OAException
  {
    // �R�~�b�g
    getOADBTransaction().commit();
  } // doCommit

  /***************************************************************************
   * (����)���[���o�b�N�������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void doRollBack() throws OAException
  {

    // ���[���o�b�N����
    XxpoUtility.rollBack(getOADBTransaction());
    
  } // doRollBack

  /***************************************************************************
   * (����)�s�}���������s�����\�b�h�ł��B
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void addRow() throws OAException
  {

    // ��������VO���擾
    OAViewObject orderDetailsVO = getXxpoOrderDetailsVO1();

    // ������VO���擾
    OAViewObject receiptDetailsVO  = getXxpoReceiptDetailsVO1();
    OARow createRow  = (OARow)receiptDetailsVO.createRow();

    // �ŐV���הԍ���ݒ�
    int newRcvRtnLineNumber = receiptDetailsVO.getRowCount() + 1;
    createRow.setAttribute("RcvRtnLineNumber", new Number(newRcvRtnLineNumber));

    // ������(����ԕi����(�A�h�I��)���o�^)�̏ꍇ
    if (receiptDetailsVO.getRowCount() == 0)
    {
      // ��������.�����P�ʂ�ݒ�
      OARow orderDetailsVORow = (OARow)orderDetailsVO.first();
      String unitName         = (String)orderDetailsVORow.getAttribute("UnitName");

      createRow.setAttribute("RcvRtnUom", unitName);

    // 1�s�ȏ�̖��ׂ����݂���ꍇ
    } else
    {

      OARow receiptDetailsVORow = (OARow)receiptDetailsVO.first();
      String uom = (String)receiptDetailsVORow.getAttribute("RcvRtnUom");

      // ����ȍ~�̎��(����ԕi����(�A�h�I��)�o�^��)�̏ꍇ
      if (!XxcmnUtility.isBlankOrNull(uom)) 
      {
        // ����ԕi����(�A�h�I��).����ԕi�P�ʂ�ݒ�
        createRow.setAttribute("RcvRtnUom", uom);

      } else
      {
        // ��������.�����P�ʂ�ݒ�
        OARow orderDetailsVORow  = (OARow)orderDetailsVO.first();
        String unitName          = (String)orderDetailsVORow.getAttribute("UnitName");

        createRow.setAttribute("RcvRtnUom", unitName);

      }

    }


    // ��������.�V�K�쐬���R�[�h�t���O��������(�V�K:TRUE)
    createRow.setAttribute("NewRowFlag", Boolean.TRUE);
    // ��������.�������/�E�vdisable�t���O��������(�V�K:FALSE)
    createRow.setAttribute("ReceiptDetailsReadOnly", Boolean.FALSE);


    receiptDetailsVO.last();
    receiptDetailsVO.next();
    receiptDetailsVO.insertRow(createRow);
    createRow.setNewRowState(Row.STATUS_INITIALIZED);

  } // addRow

  /***************************************************************************
   * (����)�s�폜�������s�����\�b�h�ł��B
   * @return String �c���R�[�h��
   * @throws OAException OA��O
   ***************************************************************************
   */
  public String deleteRow() throws OAException
  {

    // �ŏI�f�[�^���͍s�ԍ�
    Object lastInputLineNumber = null;

    // ������VO
    OAViewObject receiptDetailsVO  = getXxpoReceiptDetailsVO1();
    OARow currentRow   = null;  // ���ݍs
    OARow lastInputRow = null;  // �ŏI�f�[�^���͍s

    // ************************************ //
    // * �ŏI�f�[�^���͍s���ʏ���         * //
    // ************************************ //
    receiptDetailsVO.first();
    
    while (receiptDetailsVO.getCurrentRow() != null)
    {
      currentRow = (OARow)receiptDetailsVO.getCurrentRow();

      Object txnsDate       = currentRow.getAttribute("TxnsDate");
      Object rcvRtnQuantity = currentRow.getAttribute("RcvRtnQuantity");

      // �[�����܂��́A������ʂ̍��ڂɃf�[�^���ݒ肳��Ă���̏ꍇ
      if(!(XxcmnUtility.isBlankOrNull(txnsDate))
        || !(XxcmnUtility.isBlankOrNull(rcvRtnQuantity)))
      {

        // �ŏI�f�[�^���͍s��ޔ�
        lastInputRow = currentRow;

      }

      receiptDetailsVO.next();

    }


    // ********************************************** //
    // * �ŏI�f�[�^���͍s�ȍ~�̍s�̍폜����         * //
    // ********************************************** //
    // �S�Ă̎�����׍s�ɂ����ăf�[�^�����͂̏ꍇ�A�S�s�폜
    if (XxcmnUtility.isBlankOrNull(lastInputRow))
    {
      receiptDetailsVO.first();

      while (receiptDetailsVO.getCurrentRow() != null)
      {
        currentRow = (OARow)receiptDetailsVO.getCurrentRow();

        currentRow.remove();

        receiptDetailsVO.next();

      }
      
    } else 
    {
      // �ŏI�f�[�^���͍s�ԍ����擾
      lastInputLineNumber = lastInputRow.getAttribute("RcvRtnLineNumber");

      receiptDetailsVO.first();
    
      while (receiptDetailsVO.getCurrentRow() != null)
      {
        currentRow = (OARow)receiptDetailsVO.getCurrentRow();

        Object currentLineNumber = currentRow.getAttribute("RcvRtnLineNumber");

        // �ŏI�f�[�^���͍s�ԍ����A���ݍs�̍s�ԍ����傫���ꍇ�́A�폜����
        if(XxcmnUtility.chkCompareNumeric(1, currentLineNumber.toString(), lastInputLineNumber.toString()))
        {
          // ��s�폜
          currentRow.remove();

        }

        receiptDetailsVO.next();

      }
      
    }

    // ��s�폜������̃��R�[�h�����`�F�b�N
    int rowCount = receiptDetailsVO.getRowCount();

    return new Integer(rowCount).toString();

  } // deleteRow

  /***************************************************************************
   * (����)���[�U�[�����擾���郁�\�b�h�ł��B
   * @param row ���ݒ�VO�s
   * @throws OAException OA��O
   ***************************************************************************
   */
  public void getUserData(
    OARow row
  ) throws OAException
  {
    // ���[�U�[���擾 
    HashMap retHashMap = XxpoUtility.getUserData(
                          getOADBTransaction()  // �g�����U�N�V����
                          );

/*
    // �����������VO�擾
    OAViewObject orderReceiptSerchVO = getXxpoOrderReceiptSerchVO1();

    // 1�s�ڂ��擾
    OARow orderReceiptSerchVORow = (OARow)orderReceiptSerchVO.first();
*/

    // �]�ƈ��敪���Z�b�g
    row.setAttribute("PeopleCode", retHashMap.get("PeopleCode")); // �]�ƈ��敪

    // �]�ƈ��敪��2:�O���̏ꍇ�A�d��������Z�b�g
    if (XxpoConstants.PEOPLE_CODE_O.equals(retHashMap.get("PeopleCode")))
    {
      row.setAttribute("OutSideUsrVendorCode", retHashMap.get("VendorCode"));  // �d����R�[�h
      row.setAttribute("OutSideUsrVendorId",   retHashMap.get("VendorId"));    // �����ID
      row.setAttribute("OutSideUsrVendorName", retHashMap.get("VendorName"));  // �����ID
      row.setAttribute("OutPurchaseSiteCode",  retHashMap.get("FactoryCode")); // �d����T�C�g�R�[�h

    }
  } //getUserData


  /**
   * 
   * Container's getter for XxpoOrderReceiptMakePVO1
   */
  public OAViewObjectImpl getXxpoOrderReceiptMakePVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxpoOrderReceiptMakePVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailsVO1
   */
  public XxpoOrderDetailsVOImpl getXxpoOrderDetailsVO1()
  {
    return (XxpoOrderDetailsVOImpl)findViewObject("XxpoOrderDetailsVO1");
  }


  /**
   * 
   * Container's getter for XxpoOrderReceiptSerchVO1
   */
  public OAViewObjectImpl getXxpoOrderReceiptSerchVO1()
  {
    return (OAViewObjectImpl)findViewObject("XxpoOrderReceiptSerchVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderReceiptVO1
   */
  public XxpoOrderReceiptVOImpl getXxpoOrderReceiptVO1()
  {
    return (XxpoOrderReceiptVOImpl)findViewObject("XxpoOrderReceiptVO1");
  }

  /**
   * 
   * Container's getter for StatusCode2VO1
   */
  public OAViewObjectImpl getStatusCode2VO1()
  {
    return (OAViewObjectImpl)findViewObject("StatusCode2VO1");
  }


  /**
   * 
   * Container's getter for XxpoOrderHeaderVO1
   */
  public XxpoOrderHeaderVOImpl getXxpoOrderHeaderVO1()
  {
    return (XxpoOrderHeaderVOImpl)findViewObject("XxpoOrderHeaderVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailTotalVO1
   */
  public XxpoOrderDetailTotalVOImpl getXxpoOrderDetailTotalVO1()
  {
    return (XxpoOrderDetailTotalVOImpl)findViewObject("XxpoOrderDetailTotalVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderReceiptDetailsPVO1
   */
  public XxpoOrderReceiptDetailsPVOImpl getXxpoOrderReceiptDetailsPVO1()
  {
    return (XxpoOrderReceiptDetailsPVOImpl)findViewObject("XxpoOrderReceiptDetailsPVO1");
  }

  /**
   * 
   * Container's getter for XxpoOrderDetailsTabVO1
   */
  public XxpoOrderDetailsTabVOImpl getXxpoOrderDetailsTabVO1()
  {
    return (XxpoOrderDetailsTabVOImpl)findViewObject("XxpoOrderDetailsTabVO1");
  }

  /**
   * 
   * Container's getter for XxpoReceiptDetailsVO1
   */
  public XxpoReceiptDetailsVOImpl getXxpoReceiptDetailsVO1()
  {
    return (XxpoReceiptDetailsVOImpl)findViewObject("XxpoReceiptDetailsVO1");
  }

  /**
   * 
   * Container's getter for ApprovedReqCodeVO1
   */
  public OAViewObjectImpl getApprovedReqCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedReqCodeVO1");
  }

  /**
   * 
   * Container's getter for DropShipCodeVO1
   */
  public OAViewObjectImpl getDropShipCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("DropShipCodeVO1");
  }

  /**
   * 
   * Container's getter for ApprovedCodeVO1
   */
  public OAViewObjectImpl getApprovedCodeVO1()
  {
    return (OAViewObjectImpl)findViewObject("ApprovedCodeVO1");
  }


}