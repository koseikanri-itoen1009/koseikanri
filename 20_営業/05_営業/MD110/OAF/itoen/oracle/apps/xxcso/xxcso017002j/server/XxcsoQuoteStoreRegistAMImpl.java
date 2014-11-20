/*============================================================================
* �t�@�C���� : XxcsoQuoteStoreRegistAMImpl
* �T�v����   : �����≮�p���ϓ��͉�ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.12
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-07 1.0  SCS�y���  �V�K�쐬
* 2009-02-23 1.1  SCS�y���  [CT1-004]�}�[�W���z�̌�����12��13���ɏC��
*                            �}�[�W�����Ͱ100��菬�����ꍇ�Ͱ99.99%�A100%���
*                            �傫���ꍇ�́A99.99%���Œ�l�Ƃ��ĕ\�����Ă��邱��
* 2009-03-24 1.2  SCS�������  �y�ۑ�77�z�`�F�b�N�̊��Ԃ��v���t�@�C���l�ɏC��
* 2009-03-24 1.2  SCS�������  �yT1_0138�z�{�^��������C��
* 2009-04-13 1.3  SCS�������  �yT1_0299�zCSV�o�͐���
* 2009-04-14 1.4  SCS�������  �yT1_0461�z���Ϗ��������
* 2009-05-18 1.5  SCS�������  �yT1_1023�z���ϖ��ׂ̌�������`�F�b�N���C��
* 2009-06-16 1.6  SCS�������  �yT1_1257�z�}�[�W���z�̕ύX�C��
* 2009-07-23 1.7  SCS�������  �y0000806�z�}�[�W���z�^�}�[�W�����̌v�Z�ΏەύX
* 2009-09-10 1.8  SCS�������  �y0001331�z�}�[�W���z�̌v�Z���Ƀy�[�W�J�ڂ��w��
* 2009-12-21 1.9  SCS�������  �yE_�{�ғ�_00535�z�c�ƌ����Ή�
* 2011-04-18 1.10 SCS�g������  �yE_�{�ғ�_01373�z�ʏ�NET���i�������o�Ή�
* 2011-05-17 1.11 SCS�ː��a�K  �yE_�{�ғ�_02500�z��������`�F�b�N���@�̕ύX�Ή�
* 2011-11-14 1.12 SCSK�ː��a�K �yE_�{�ғ�_08312�z�≮���ω�ʂ̉��C�@
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;

import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.BlobDomain;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso017002j.util.XxcsoQuoteConstants;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;

/*******************************************************************************
 * �����≮�p���ϓ��͉�ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteStoreRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteStoreRegistAMImpl()
  {
  }

  /*****************************************************************************
   * ���s�敪�u�Ȃ��v�̏ꍇ�̏���������
   * @param quoteHeaderId          ���σw�b�_�[ID
   * @param referenceQuoteHeaderId �Q�Ɨp���σw�b�_�[ID
   * @param tranDiv                ���s�敪
   *****************************************************************************
   */
  public void initDetails(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �g�����U�N�V������������
    rollback();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");
    }

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    initVo.executeQuery();

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    headerVo.initQuery(quoteHeaderId);

    headerVo.first();

    if (quoteHeaderId == null || "".equals(quoteHeaderId.trim()))
    {

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

      headerVo.insertRow(headerRow);

      // �{�^�������_�����O����
      initRender();
      
      // �����l�ݒ�
      headerRow.setPublishDate(
        initRow.getCurrentDate()
      );
      headerRow.setQuoteType(
        XxcsoQuoteConstants.QUOTE_STORE
      );
      headerRow.setDelivPlace(
        XxcsoQuoteConstants.DEF_DELIV_PLACE
      );
      headerRow.setPaymentCondition(
        XxcsoQuoteConstants.DEF_PAYMENT_CONDITION
      );
      headerRow.setStatus(
        XxcsoQuoteConstants.QUOTE_INPUT
      );
      headerRow.setUnitType(
        XxcsoQuoteConstants.DEF_UNIT_TYPE
      );
      headerRow.setDelivPriceTaxType(
        XxcsoQuoteConstants.DEF_DELIV_PRICE_TAX_TYPE
      );
      headerRow.setBaseCode(
        initRow.getWorkBaseCode()
      );
      headerRow.setBaseName(
        initRow.getWorkBaseName()
      );
      headerRow.setEmployeeNumber(
        initRow.getEmployeeNumber()
      );
      headerRow.setFullName(
        initRow.getFullName()
      );
      // �̔��p���ω�ʂ���J�ڂ��Ă����ꍇ
      if ( referenceQuoteHeaderId != null )
      {
        headerRow.setReferenceQuoteHeaderId(
          new Number(Integer.parseInt(referenceQuoteHeaderId))
        );
      }
    }
    else
    {
      // �{�^�������_�����O����
      initRender();

      // ���ϖ���
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���s�敪�uCOPY�v�̏ꍇ�̏���������
   * @param quoteHeaderId          ���σw�b�_�[ID
   * @param referenceQuoteHeaderId �Q�Ɨp���σw�b�_�[ID
   * @param tranDiv                ���s�敪
   *****************************************************************************
   */
  public void initDetailsCopy(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // XxcsoQuoteHeadersFullVO1�C���X�^���X�̎擾
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // XxcsoQuoteHeaderStoreSumVO1�C���X�^���X�̎擾
    XxcsoQuoteHeaderStoreSumVOImpl headerVo2 = getXxcsoQuoteHeaderStoreSumVO1();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeaderStoreSumVO1");
    }

    // XxcsoQuoteLinesStoreFullVO1�C���X�^���X�̎擾
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // XxcsoQuoteLineStoreSumVO1�C���X�^���X�̎擾
    XxcsoQuoteLineStoreSumVOImpl lineVo2 = getXxcsoQuoteLineStoreSumVO1();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLineStoreSumVO1");
    }

    // XxcsoQuoteStoreInitVO1�C���X�^���X�̎擾
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    // ������
    headerVo.initQuery((String)null);
    // �J�[�\����擪�ɂ���
    headerVo.first();
    lineVo.first();
        
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // ����
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeaderStoreSumVORowImpl headerRow2
      = (XxcsoQuoteHeaderStoreSumVORowImpl)headerVo2.first();

    // �������pVO�̌���
    initVo.executeQuery();
    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    // �R�s�[
    headerRow.setReferenceQuoteNumber(
      headerRow2.getReferenceQuoteNumber()
    );
    headerRow.setReferenceQuoteHeaderIdNoBuild(
      headerRow2.getReferenceQuoteHeaderId()
    );
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setStoreName(
      headerRow2.getStoreName()
    );
    headerRow.setPublishDate(         
      initRow.getCurrentDate()          
    );
    headerRow.setAccountNumber(       
      headerRow2.getAccountNumber()      
    );
    headerRow.setPartyName(
      headerRow2.getPartyName()
    );
    headerRow.setEmployeeNumber(      
      initRow.getEmployeeNumber()       
    );
    headerRow.setFullName(            
      initRow.getFullName()             
    );
    headerRow.setBaseCode(            
      initRow.getWorkBaseCode()         
    );
    headerRow.setBaseName(            
      initRow.getWorkBaseName()         
    );
    headerRow.setDelivPlace(          
      headerRow2.getDelivPlace()        
    );
    headerRow.setPaymentCondition(    
      headerRow2.getPaymentCondition()  
    );
    headerRow.setQuoteSubmitName(     
      headerRow2.getQuoteSubmitName()   
    );
    headerRow.setStatus(              
      /* 20090324_abe_T1_0138 START*/
      //XxcsoQuoteConstants.QUOTE_INPUT   
      XxcsoQuoteConstants.QUOTE_INIT   
      /* 20090324_abe_T1_0138 END*/
    );
    headerRow.setSalesUnitType(            
      headerRow2.getSalesUnitType()          
    );
    headerRow.setDelivPriceTaxType(   
      headerRow2.getDelivPriceTaxType() 
    );
    headerRow.setStorePriceTaxType(   
      headerRow2.getStorePriceTaxType() 
    );
    headerRow.setUnitType(            
      headerRow2.getUnitType()          
    );
    headerRow.setSpecialNote(         
      headerRow2.getSpecialNote()       
    );

    // ���ׂ̃R�s�[
    XxcsoQuoteLineStoreSumVORowImpl lineRow2
      = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.first();

    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);
      
      // �R�s�[
      if( "Y".equals(lineRow2.getSelectFlag()) )
      {
        lineRow.setQuoteLineId(
          lineRow2.getReferenceQuoteLineId()
        );
      }

      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setItemShortName(      
        lineRow2.getItemShortName()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/
      lineRow.setUsuallyDelivPrice(      
        lineRow2.getUsuallyDelivPrice()      
      );
      lineRow.setUsuallyStoreSalePrice(  
        lineRow2.getUsuallyStoreSalePrice()  
      );
      lineRow.setThisTimeDelivPrice(     
        lineRow2.getThisTimeDelivPrice()     
      );
      lineRow.setThisTimeStoreSalePrice( 
        lineRow2.getThisTimeStoreSalePrice() 
      );
      lineRow.setQuotationPrice(                
        lineRow2.getQuotationPrice()                
      );
      lineRow.setSalesDiscountPrice(                
        lineRow2.getSalesDiscountPrice()                
      );
      lineRow.setUsuallNetPrice(                
        lineRow2.getUsuallNetPrice()                
      );
      lineRow.setThisTimeNetPrice(                
        lineRow2.getThisTimeNetPrice()                
      );
      lineRow.setAmountOfMargin(                
        lineRow2.getAmountOfMargin()                
      );
      lineRow.setMarginRate(                
        lineRow2.getMarginRate()                
      );
      lineRow.setQuoteEndDate(
        lineRow2.getQuoteEndDate()
      );
      lineRow.setRemarks(
        lineRow2.getRemarks()
      );
      lineRow.setLineOrder(              
        lineRow2.getLineOrder()              
      );
      lineRow.setBusinessPrice(          
        lineRow2.getBusinessPrice()          
      );
      lineRow.setSelectFlag(
        lineRow2.getSelectFlag()
      );

      // �R�s�[������ɏ�����
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      lineRow2 = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();

    // �{�^�������_�����O����
    initRender();
    
    /* 20090324_abe_T1_0138 START*/
    headerRow.setStatus(              
      XxcsoQuoteConstants.QUOTE_INPUT   
    );
    /* 20090324_abe_T1_0138 END*/

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���s�敪�uREVISION_UP�v�̏ꍇ�̏���������
   * @param quoteHeaderId          ���σw�b�_�[ID
   * @param referenceQuoteHeaderId �Q�Ɨp���σw�b�_�[ID
   * @param tranDiv                ���s�敪
   *****************************************************************************
   */
  public void initDetailsRevisionUp(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // XxcsoQuoteHeadersFullVO1�C���X�^���X�̎擾
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // XxcsoQuoteHeaderStoreSumVO1�C���X�^���X�̎擾
    XxcsoQuoteHeaderStoreSumVOImpl headerVo2 = getXxcsoQuoteHeaderStoreSumVO1();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeaderStoreSumVO1");
    }

    // XxcsoQuoteLinesStoreFullVO1�C���X�^���X�̎擾
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // XxcsoQuoteLineStoreSumVO1�C���X�^���X�̎擾
    XxcsoQuoteLineStoreSumVOImpl lineVo2 = getXxcsoQuoteLineStoreSumVO1();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLineStoreSumVO1");
    }

    // XxcsoQuoteStoreInitVO1�C���X�^���X�̎擾
    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    // ������
    headerVo.initQuery((String)null);
    // �J�[�\����擪�ɂ���
    headerVo.first();
    lineVo.first();
        
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // ����
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeaderStoreSumVORowImpl headerRow2
      = (XxcsoQuoteHeaderStoreSumVORowImpl)headerVo2.first();

    // �������pVO�̌���
    initVo.executeQuery();
    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    // ���������擾
    int attrNum = headerVo.getAttributeCount();

     // �R�s�[
    headerRow.setReferenceQuoteNumber(
      headerRow2.getReferenceQuoteNumber()
    );
    headerRow.setReferenceQuoteHeaderIdNoBuild(
      headerRow2.getReferenceQuoteHeaderId()
    );
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setStoreName(
      headerRow2.getStoreName()
    );
    headerRow.setQuoteNumber(
      headerRow2.getQuoteNumber()       
    );
    headerRow.setQuoteRevisionNumber(
      headerRow2.getQuoteRevisionNumber().add(1)
    );
    headerRow.setPublishDate(         
      initRow.getCurrentDate()          
    );
    headerRow.setAccountNumber(       
      headerRow2.getAccountNumber()      
    );
    headerRow.setPartyName(
      headerRow2.getPartyName()
    );
    headerRow.setEmployeeNumber(      
      initRow.getEmployeeNumber()       
    );
    headerRow.setFullName(            
      initRow.getFullName()             
    );
    headerRow.setBaseCode(            
      initRow.getWorkBaseCode()         
    );
    headerRow.setBaseName(            
      initRow.getWorkBaseName()         
    );
    headerRow.setDelivPlace(          
      headerRow2.getDelivPlace()        
    );
    headerRow.setPaymentCondition(    
      headerRow2.getPaymentCondition()  
    );
    headerRow.setQuoteSubmitName(     
      headerRow2.getQuoteSubmitName()   
    );
    headerRow.setStatus(              
      /* 20090324_abe_T1_0138 START*/
      //XxcsoQuoteConstants.QUOTE_INPUT   
      XxcsoQuoteConstants.QUOTE_INIT   
      /* 20090324_abe_T1_0138 END*/
    );
    headerRow.setSalesUnitType(            
      headerRow2.getSalesUnitType()          
    );
    headerRow.setDelivPriceTaxType(   
      headerRow2.getDelivPriceTaxType() 
    );
    headerRow.setStorePriceTaxType(   
      headerRow2.getStorePriceTaxType() 
    );
    headerRow.setUnitType(            
      headerRow2.getUnitType()          
    );
    headerRow.setSpecialNote(         
      headerRow2.getSpecialNote()       
    );

    // �������̃X�e�[�^�X�����łɂ���
    headerRow2.setStatus(XxcsoQuoteConstants.QUOTE_OLD);
    
    // ���ׂ̃R�s�[
    XxcsoQuoteLineStoreSumVORowImpl lineRow2
      = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();
      
      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      // �R�s�[
      if( "Y".equals(lineRow2.getSelectFlag()) )
      {
        lineRow.setQuoteLineId(
          lineRow2.getReferenceQuoteLineId()
        );
      }
      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setItemShortName(      
        lineRow2.getItemShortName()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
      /* 20090616_abe_T1_1257 START*/
      lineRow.setBowlIncNum(
        lineRow2.getBowlIncNum()
      );
      lineRow.setCaseIncNum(
        lineRow2.getCaseIncNum()
      );
      /* 20090616_abe_T1_1257 END*/

      lineRow.setUsuallyDelivPrice(      
        lineRow2.getUsuallyDelivPrice()      
      );
      lineRow.setUsuallyStoreSalePrice(  
        lineRow2.getUsuallyStoreSalePrice()  
      );
      lineRow.setThisTimeDelivPrice(     
        lineRow2.getThisTimeDelivPrice()     
      );
      lineRow.setThisTimeStoreSalePrice( 
        lineRow2.getThisTimeStoreSalePrice() 
      );
      lineRow.setQuotationPrice(                
        lineRow2.getQuotationPrice()                
      );
      lineRow.setSalesDiscountPrice(                
        lineRow2.getSalesDiscountPrice()                
      );
      lineRow.setUsuallNetPrice(                
        lineRow2.getUsuallNetPrice()                
      );
      lineRow.setThisTimeNetPrice(                
        lineRow2.getThisTimeNetPrice()                
      );
      lineRow.setAmountOfMargin(                
        lineRow2.getAmountOfMargin()                
      );
      lineRow.setMarginRate(                
        lineRow2.getMarginRate()                
      );
      lineRow.setQuoteEndDate(
        lineRow2.getQuoteEndDate()
      );
      lineRow.setRemarks(                
        lineRow2.getRemarks()                
      );
      lineRow.setLineOrder(              
        lineRow2.getLineOrder()              
      );
      lineRow.setBusinessPrice(          
        lineRow2.getBusinessPrice()          
      );
      lineRow.setSelectFlag(
        lineRow2.getSelectFlag()
      );

      // �R�s�[������ɏ�����
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      lineRow2 = (XxcsoQuoteLineStoreSumVORowImpl)lineVo2.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    // �{�^�������_�����O����
    initRender();

    /* 20090324_abe_T1_0138 START*/
    headerRow.setStatus(              
      XxcsoQuoteConstants.QUOTE_INPUT   
    );
    /* 20090324_abe_T1_0138 END*/

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ����{�^������������
   *****************************************************************************
   */
  public HashMap handleCancelButton(
    String referenceQuoteHeaderId,
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ύX���e������������
    rollback();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    HashMap params = new HashMap();

    // ���σw�b�_�[ID
    if ( headerRow != null )
    {
      params.put(
        XxcsoConstants.TRANSACTION_KEY1,
        headerRow.getReferenceQuoteHeaderId()
      );
    }
    else
    {
      params.put(
        XxcsoConstants.TRANSACTION_KEY1,
        referenceQuoteHeaderId
      );
    }

    // ���s�敪
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_UPDATE
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * �R�s�[�̍쐬�{�^������������
   * @return HashMap     URL�p�����[�^
   * @param returnPgName �߂���ʖ���
   *****************************************************************************
   */
  public HashMap handleCopyCreateButton(
    String referenceQuoteHeaderId,
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ύX���e������������
    rollback();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    HashMap params = new HashMap();

   // ���σw�b�_�[ID
    params.put(
      XxcsoConstants.TRANSACTION_KEY1,
      headerRow.getQuoteHeaderId()
    );
   // �߂���ʖ���
    params.put(
      XxcsoConstants.TRANSACTION_KEY3,
      returnPgName
    );
    // ���s�敪
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_COPY
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 
  }

  /*****************************************************************************
   * �����ɂ���{�^������������
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public OAException handleInvalidityButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ύX���e������������
    rollback();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

   // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // �X�e�[�^�X���X�V
    headerRow.setStatus( XxcsoQuoteConstants.QUOTE_INVALIDITY );

    // �ۑ����������s���܂��B
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
          ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_INVALID
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * �K�p�{�^������������
   * @return HashMap ����I�����b�Z�[�W,URL�p�����[�^
   * @param returnPgName �߂���ʖ���
   *****************************************************************************
   */
  public HashMap handleApplicableButton(
    String referenceQuoteHeaderId,
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    List errorList = new ArrayList();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // ���̓`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    // ���ϖ���
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    // �Q�Ɨp���ϔԍ�
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getReferenceQuoteNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
         ,0
        );

    // �ڋq�R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getAccountNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_ACCOUNT_NUMBER
         ,0
        );

    // �[���ꏊ
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getDelivPlace()
         ,XxcsoQuoteConstants.TOKEN_VALUE_DELIV_PLACE
         ,0
        );

    // �x������
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getPaymentCondition()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PAYMENT_CONDITION
         ,0
        );

    // ���Ϗ���o�於
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getQuoteSubmitName()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_SUBMIT_NAME
         ,0
        );

    // ���L����
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getSpecialNote()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SPECIAL_NOTE
         ,0
        );

    int index = 0;
    
    while ( lineRow != null )
    {
      index++;

      if( "Y".equals(lineRow.getSelectFlag()) )
      {
/* 20090616_abe_T1_1257 START*/
        handleMarginCalculation(
          lineRow.getQuoteLineId().toString()
        );
/* 20090616_abe_T1_1257 END*/

        //DB���f�`�F�b�N      
        errorList
          = validateLine(
              errorList
             ,lineRow
             ,index
            );
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

/* 20090910_abe_0001331 START*/
    lineVo.first();
/* 20090910_abe_0001331 END*/

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // �ۑ����������s���܂��B
    commit();

    HashMap params = new HashMap(3);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoQuoteConstants.TRANDIV_UPDATE
    );

    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getQuoteHeaderId()
    );

    params.put(
      XxcsoConstants.TRANSACTION_KEY3
     ,returnPgName
    );

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoQuoteConstants.RETURN_PARAM_URL
     ,params
    );
    returnValue.put(
      XxcsoQuoteConstants.RETURN_PARAM_MSG
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * �ł̉����{�^������������
   * @return HashMap URL�p�����[�^
   * @param returnPgName �߂���ʖ���
   *****************************************************************************
   */
  public HashMap handleRevisionButton(
    String referenceQuoteHeaderId,
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ύX���e������������
    rollback();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    HashMap params = new HashMap();

    // ���σw�b�_�[ID
    params.put(
      XxcsoConstants.TRANSACTION_KEY1,
      headerRow.getQuoteHeaderId()
    );
    // �߂���ʖ���
    params.put(
      XxcsoConstants.TRANSACTION_KEY3
     ,returnPgName
    );
    // ���s�敪
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_REVISION_UP
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * �m��{�^������������
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public OAException handleFixedButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();
    
    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // ��ʍ��ڂ̓��̓`�F�b�N
    validateFixed();

    // �X�e�[�^�X���X�V
    headerRow.setStatus( XxcsoQuoteConstants.QUOTE_FIXATION );

    // �̔��p���ω�ʂ���J�ڂ��Ă����ꍇ�͔̔��p���X�e�[�^�X���X�V����
    handleupdatesales();

    // �ۑ����������s���܂��B
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_NUMBER
            + headerRow.getQuoteNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER2
            + XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_REV_NUMBER
            + headerRow.getQuoteRevisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_FIXATION
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * ���Ϗ�����{�^������������
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public OAException handlePdfCreateButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
      /* 20090414_abe_T1_0461 START*/
      //if ( getTransaction().isDirty() )
      //{
      /* 20090414_abe_T1_0461 END*/
        // ��ʍ��ڂ̓��̓`�F�b�N
        validateFixed();

        // �ۑ����������s���܂��B
        commit();
      /* 20090414_abe_T1_0461 START*/
      //}
      /* 20090414_abe_T1_0461 END*/
    }
    else
    {
      rollback();
    }

    // ���Ϗ����PG��CALL
    NUMBER requestId = null;
    OracleCallableStatement stmt = null;
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  :1 := fnd_request.submit_request(");
      sql.append("         application       => 'XXCSO'");
      sql.append("        ,program           => 'XXCSO017A04C'");
      sql.append("        ,description       => NULL");
      sql.append("        ,start_time        => NULL");
      sql.append("        ,sub_request       => FALSE");
      sql.append("        ,argument1         => :2");
      sql.append("       );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.registerOutParameter(1, OracleTypes.NUMBER);
      stmt.setString(2, headerRow.getQuoteHeaderId().stringValue());

      stmt.execute();
      
      requestId = stmt.getNUMBER(1);
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e
         ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }

    if ( NUMBER.zero().equals(requestId) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(50);
        sql.append("BEGIN fnd_message.retrieve(:1); END;");

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.registerOutParameter(1, OracleTypes.VARCHAR);

        stmt.execute();

        String errmsg = stmt.getString(1);

        throw
          XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00310
           ,XxcsoConstants.TOKEN_CONC
           ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
           ,XxcsoConstants.TOKEN_CONCMSG
           ,errmsg
          );
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
          );
      }
      finally
      {
        try
        {
          if ( stmt != null )
          {
            stmt.close();
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
        }
      }
    }

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoQuoteConstants.TOKEN_VALUE_PDF_OUT
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
            + requestId.stringValue()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoQuoteConstants.TOKEN_VALUE_START
        );

    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * CSV�쐬�{�^������������
   * @return OAException ����I�����b�Z�[�W
   *****************************************************************************
   */
  public OAException handleCsvCreateButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
      /* 20090414_abe_T1_0461 START*/
      //if ( getTransaction().isDirty() )
      //{
      /* 20090414_abe_T1_0461 END*/
        // ��ʍ��ڂ̓��̓`�F�b�N
        validateFixed();

        // �ۑ����������s���܂��B
        commit();
      /* 20090414_abe_T1_0461 START*/
      //}
      /* 20090414_abe_T1_0461 END*/
    }
    else
    {
      rollback();
    }

    // CSV�t�@�C���쐬
    XxcsoCsvQueryVOImpl queryVo = getXxcsoCsvQueryVO1();
    String sql = queryVo.getQuery();

    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;

    // �v���t�@�C���̎擾
    String clientEnc = txn.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    StringBuffer sbFileData = new StringBuffer();

    try
    {
      stmt = (OracleCallableStatement)txn.createCallableStatement(sql, 0);
      stmt.setNUMBER(1, headerRow.getQuoteHeaderId());

      rs = (OracleResultSet)stmt.executeQuery();

      while ( rs.next() )
      {
        // �o�͗p�o�b�t�@�֊i�[
        int rsIdx = 1;
        
        // ����:���ώ��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϔԍ�
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���s��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ڋq�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ڋq��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�]�ƈ��ԍ�
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�]�ƈ�����
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���_�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���_��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�[���ꏊ
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�x������
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ��J�n��
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ��I����
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϒ�o�於
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�X�[���i�ŋ敪
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�������i�ŋ敪
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�P���ŋ敪
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�X�e�[�^�X
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���L����
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i����
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϋ敪
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�X�[���i
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�X������
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����X�[���i
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����X������
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ԁi�J�n�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ԁi�I���j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���l
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���я�
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ώ�ʁi�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�Q�Ɨp���ϔԍ��i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�≮�����於�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϔԍ��i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�Łi�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���s���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ڋq�R�[�h�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ڋq���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�S���҃R�[�h�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�S���Җ��i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���_�R�[�h�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���_���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�[���ꏊ�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�x�������i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ����ԁi�J�n�j�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ����ԁi�I���j�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ���o�於�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�X�e�[�^�X�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�̔���P���敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�≮�P���敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ŋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���L�����i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i�R�[�h�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�X�[���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����X�[���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���l�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����l���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�m�d�s���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����m�d�s���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�}�[�W���z�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�}�[�W�����i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ԁi�J�n�j�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ԁi�I���j�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���l�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���я��i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);


        // ����:���i��������
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:JAN�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�P�[�XJAN�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:ITF�R�[�h
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�e��敪
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�艿�i�V�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), true);
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw
        XxcsoMessage.createSqlErrorMessage(
          e,
          XxcsoConstants.TOKEN_VALUE_CSV_CREATE
        );
    }
    finally
    {
      try
      {
        if ( rs != null )
        {
          rs.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
      }
    }
    
    // VO�ւ̃t�@�C�����A�t�@�C���f�[�^�̐ݒ�
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVO1");
    }

    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();

    // *****CSV�t�@�C�����p���t������(yyyymmdd)
    StringBuffer sbDate = new StringBuffer(8);
    String nowDate = txn.getCurrentUserDate().dateValue().toString();
    sbDate.append(nowDate.substring(0, 4));
    sbDate.append(nowDate.substring(5, 7));
    sbDate.append(nowDate.substring(8, 10));

    // *****CSV�t�@�C�����̐���(���ϔԍ�_yyyymmdd_�A��)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(headerRow.getQuoteNumber());
    sbFileName.append(XxcsoQuoteConstants.CSV_NAME_DELIMITER);
    sbFileName.append(sbDate);
    sbFileName.append(XxcsoQuoteConstants.CSV_NAME_DELIMITER);
    sbFileName.append((csvVo.getRowCount() + 1));
    sbFileName.append(XxcsoQuoteConstants.CSV_EXTENSION);

    try
    {
      // *****�t�@�C�����A�t�@�C���f�[�^��ݒ�
      csvRowVo.setFileName(new String(sbFileName));
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw XxcsoMessage.createCsvErrorMessage(uae);
    }

    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // �������b�Z�[�W��ݒ肷��
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoQuoteConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoQuoteConstants.MSG_DISP_OUT
        );
    
    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * �Q�Ɨp���ϔԍ����ڂ̐��䏈��
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo
      = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteStoreInitVO1"
        );
    }
    
    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( headerRow != null )
    {
      if ( headerRow.getReferenceQuoteHeaderId() != null )
      {
        initRow.setRefQuoteNumberRender(Boolean.FALSE);
        initRow.setRefQuoteNumberViewRender(Boolean.TRUE);
      }
      else
      {
        initRow.setRefQuoteNumberRender(Boolean.TRUE);
        initRow.setRefQuoteNumberViewRender(Boolean.FALSE);
      }
    }
    else
    {
        initRow.setRefQuoteNumberRender(Boolean.TRUE);
        initRow.setRefQuoteNumberViewRender(Boolean.FALSE);      
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �ŋ敪���ڂ̐��䏈��
   * @param quoteHeaderId          ���σw�b�_�[ID
   * @param referenceQuoteHeaderId �Q�Ɨp���σw�b�_�[ID
   * @param tranDiv                ���s�敪
   *****************************************************************************
   */
  public void setAttributeTaxType(
    String quoteHeaderId,
    String referenceQuoteHeaderId,
    String tranDiv
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo
      = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteStoreInitVO1"
        );
    }
    
    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.TRANDIV_UPDATE.equals(tranDiv) ||
      XxcsoQuoteConstants.TRANDIV_CREATE.equals(tranDiv) )
    {
      initRow.setDelivPriceTaxTypeRender(Boolean.FALSE);
      initRow.setDelivPriceTaxTypeViewRender(Boolean.TRUE);
    }
    else
    {
      initRow.setDelivPriceTaxTypeRender(Boolean.TRUE);
      initRow.setDelivPriceTaxTypeViewRender(Boolean.FALSE);
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �|�b�v���X�g����������
   *****************************************************************************
   */
  public void initPoplist()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // *************************
    // *****poplist�̐���*******
    // *************************
    // *****���ώ��
    XxcsoLookupListVOImpl quoteTypeLookupVo =
      getXxcsoQuoteTypeLookupVO();
    if (quoteTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteTypeListVO");
    }
    // lookup�̏�����
    quoteTypeLookupVo.initQuery("XXCSO1_QUOTE_TYPE", "1");

    // *****�X�e�[�^�X
    XxcsoLookupListVOImpl quoteStatusLookupVo =
      getXxcsoQuoteStatusLookupVO();
    if (quoteStatusLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteStatusLookupVO");
    }
    // lookup�̏�����
    quoteStatusLookupVo.initQuery("XXCSO1_QUOTE_STATUS", "1");

    // *****�̔���P���敪
    XxcsoLookupListVOImpl unitPriceSalesLookupVo
        = getXxcsoUnitPriceSalesLookupVO();

    if (unitPriceSalesLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceSalesLookupVO");
    }
    // lookup�̏�����
    unitPriceSalesLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

    // *****�ŋ敪
    XxcsoLookupListVOImpl delivPriceTaxTypeLookupVo =
      getXxcsoDelivPriceTaxTypeLookupVO();
    if (delivPriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDelivPriceTaxDivLookupVO");
    }
    // lookup�̏�����
    delivPriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");
      
    // *****�≮�P���敪
    XxcsoLookupListVOImpl unitPriceStoreLookupVo
        = getXxcsoUnitPriceStoreLookupVO();

    if (unitPriceStoreLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceStoreLookupVO");
    }
    // lookup�̏�����
    unitPriceStoreLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

    // *****���ϋ敪
    XxcsoLookupListVOImpl quoteDivLookupVo = getXxcsoQuoteDivLookupVO();
    if (quoteDivLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteDivLookupVO");
    }
    // lookup�̏�����
    quoteDivLookupVo.initQuery("XXCSO1_QUOTE_DIVISION", "1");

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �}�[�W���Z�o���s������
   * @param quoteLineId ���ϖ���ID
   *****************************************************************************
   */
  public void handleMarginCalculation(
    String quoteLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    /* 20090616_abe_T1_1257 START*/
    // XxcsoQuoteHeadersFullVO1�C���X�^���X�̎擾
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    /* 20090616_abe_T1_1257 END*/


    // XxcsoQuoteLinesStoreFullVO1�C���X�^���X�̎擾
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( quoteLineId.equals(lineRow.getQuoteLineId().stringValue()) )
      {

        // �Z�o�p���[�N�̏����l
        String netPrice = XxcsoQuoteConstants.DEF_PRICE;
        BigDecimal defRate = new BigDecimal(XxcsoQuoteConstants.DEF_RATE);

/* 20090723_abe_0000806 START*/
        //// ���ϋ敪���u1�v�̏ꍇ�́A�ʏ퉿�i�ŎZ�o�B����ȊO�͍��񉿊i�ŎZ�o���܂��B
        //if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
        //       lineRow.getQuoteDiv())
        //   )
        //{
        // ����X�[���i���ݒ�Ȃ��̏ꍇ�́A�ʏ퉿�i�ŎZ�o�B����ȊO�͍��񉿊i�ŎZ�o���܂��B
        if ( lineRow.getThisTimeDelivPrice() == null )
        {
/* 20090723_abe_0000806 END*/
          // �}�[�W���z���Z�o
          if ( lineRow.getUsuallNetPrice() == null )
          {
            netPrice = XxcsoQuoteConstants.DEF_PRICE;
          }
          else
          {
            netPrice = lineRow.getUsuallNetPrice();
          }

          try
          {
            // �v�Z
            BigDecimal Price1
              = new BigDecimal(
                lineRow.getUsuallyDelivPrice().replaceAll(",","")
              );
            BigDecimal Price2 = new BigDecimal(netPrice.replaceAll(",",""));
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceSubtract = Price1.subtract(Price2);
            BigDecimal PriceSalesSubtract;
            BigDecimal PriceStoreSubtract;
            BigDecimal PriceSubtract = BigDecimal.valueOf(0);

            BigDecimal DecCase_num = BigDecimal.valueOf(0);
            BigDecimal DecBowl_num = BigDecimal.valueOf(0);
            
            //�����`�F�b�N(�̔��P���敪)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getSalesUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0)== 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getSalesUnitType())))
              )
            {
              PriceSalesSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //�̔��P���敪���{���̏ꍇ
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getSalesUnitType()))
              {
                PriceSalesSubtract = Price1;
              }
              //�̔��P���敪��C/S�̏ꍇ
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getSalesUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //�̔��P���敪���{�[���̏ꍇ
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //�����`�F�b�N(�≮�P���敪)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0)== 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getUnitType())))
              )
            {
              PriceStoreSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //�P���敪���{���̏ꍇ
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getUnitType()))
              {
                PriceStoreSubtract = Price2;
              }
              //�P���敪��C/S�̏ꍇ
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getUnitType()))
              {
                DecCase_num = 
                  lineRow.getCaseIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //�P���敪���{�[���̏ꍇ
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }

            //�}�[�W�z�v�Z
            PriceSubtract = PriceSalesSubtract.subtract(PriceStoreSubtract);
            /* 20090616_abe_T1_1257 END*/

            // �}�[�W���z�Ɍv�Z���ʂ𔽉f���܂��B
            lineRow.setAmountOfMargin(String.valueOf(PriceSubtract));

            // �}�[�W�������Z�o
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceDivide = PriceSubtract.divide(
            //  Price1,6,BigDecimal.ROUND_HALF_UP);
            BigDecimal PriceDivide = BigDecimal.valueOf(0);
            if (PriceSalesSubtract.doubleValue() != 0)
            {
              PriceDivide = PriceSubtract.divide(
                PriceSalesSubtract,6,BigDecimal.ROUND_HALF_UP);
            }
            /* 20090616_abe_T1_1257 END*/

            BigDecimal PriceMultiply = PriceDivide.multiply(defRate);

            BigDecimal PriceScale 
              = PriceMultiply.setScale(2, BigDecimal.ROUND_HALF_UP);

            // �}�[�W�����Ɍv�Z���ʂ𔽉f���܂��B
            BigDecimal limitMin
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MIN);
            BigDecimal limitMax
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MAX);

            // -100��菬�����ꍇ��-99.99�Œ�Ƃ��܂�
            if ( limitMin.compareTo(PriceScale) == 1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MIN);
            }
            // 100���傫���ꍇ��99.99�Œ�Ƃ��܂�
            else if ( limitMax.compareTo(PriceScale) == -1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MAX);
            }
            else
            {
              lineRow.setMarginRate(String.valueOf(PriceScale));
            }
          }
          catch ( NumberFormatException e )
          {
            XxcsoUtils.debug(txn, "NumberFormatException");
          }
        }
        else
        {
          // �}�[�W���z���Z�o
          if ( lineRow.getThisTimeNetPrice() == null )
          {
            netPrice = XxcsoQuoteConstants.DEF_PRICE;
          }
          else
          {
            netPrice = lineRow.getThisTimeNetPrice();
          }
          try
          {
            // �v�Z
            BigDecimal Price1
              = new BigDecimal(
                lineRow.getThisTimeDelivPrice().replaceAll(",","")
              );
            BigDecimal Price2 = new BigDecimal(netPrice.replaceAll(",",""));

            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceSubtract = Price1.subtract(Price2);
            BigDecimal PriceSalesSubtract;
            BigDecimal PriceStoreSubtract;
            BigDecimal PriceSubtract = BigDecimal.valueOf(0);

            BigDecimal DecCase_num = BigDecimal.valueOf(0);
            BigDecimal DecBowl_num = BigDecimal.valueOf(0);
            
            //�����`�F�b�N(�̔��P���敪)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getSalesUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getSalesUnitType())))
              )
            {
              PriceSalesSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //�̔��P���敪���{���̏ꍇ
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getSalesUnitType()))
              {
                PriceSalesSubtract = Price1;
              }
              //�̔��P���敪��C/S�̏ꍇ
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getSalesUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //�̔��P���敪���{�[���̏ꍇ
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceSalesSubtract = Price1.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //�����`�F�b�N(�≮�P���敪)
            if(((lineRow.getCaseIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
                 headerRow.getUnitType()))) || 
                ((lineRow.getBowlIncNum().compareTo(0) == 0) &&
                (XxcsoQuoteConstants.DEF_UNIT_TYPE3.equals(
                 headerRow.getUnitType())))
              )
            {
              PriceStoreSubtract = BigDecimal.valueOf(0);
            }
            else
            {
              //�P���敪���{���̏ꍇ
              if(XxcsoQuoteConstants.DEF_UNIT_TYPE1.equals(
              headerRow.getUnitType()))
              {
                PriceStoreSubtract = Price2;
              }
              //�P���敪��C/S�̏ꍇ
              else if(XxcsoQuoteConstants.DEF_UNIT_TYPE2.equals(
              headerRow.getUnitType()))
              {
                DecCase_num = 
                   lineRow.getCaseIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecCase_num,2,BigDecimal.ROUND_HALF_UP);
              }
              //�P���敪���{�[���̏ꍇ
              else
              {
                DecBowl_num =
                   lineRow.getBowlIncNum().bigDecimalValue();
                PriceStoreSubtract = Price2.divide(
                DecBowl_num,2,BigDecimal.ROUND_HALF_UP);
              }
            }
            //�}�[�W�z�v�Z
            PriceSubtract = PriceSalesSubtract.subtract(PriceStoreSubtract);
            /* 20090616_abe_T1_1257 END*/

            // �}�[�W���z�Ɍv�Z���ʂ𔽉f���܂��B
            lineRow.setAmountOfMargin(String.valueOf(PriceSubtract));

            // �}�[�W�������Z�o
            /* 20090616_abe_T1_1257 START*/
            //BigDecimal PriceDivide = PriceSubtract.divide(
            //  Price1,6,BigDecimal.ROUND_HALF_UP);
            BigDecimal PriceDivide = BigDecimal.valueOf(0);
            if (PriceSalesSubtract.doubleValue() != 0)
            {
              PriceDivide = PriceSubtract.divide(
                PriceSalesSubtract,6,BigDecimal.ROUND_HALF_UP);
            }
            /* 20090616_abe_T1_1257 END*/

            BigDecimal PriceMultiply = PriceDivide.multiply(defRate);

            BigDecimal PriceScale 
              = PriceMultiply.setScale(2, BigDecimal.ROUND_HALF_UP);

            // �}�[�W�����Ɍv�Z���ʂ𔽉f���܂��B
            BigDecimal limitMin
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MIN);
            BigDecimal limitMax
              = new BigDecimal(XxcsoQuoteConstants.RATE_LIMIT_MAX);

            // -100��菬�����ꍇ��-99.99�Œ�Ƃ��܂�
            if ( limitMin.compareTo(PriceScale) == 1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MIN);
            }
            // 100���傫���ꍇ��99.99�Œ�Ƃ��܂�
            else if ( limitMax.compareTo(PriceScale) == -1 )
            {
              lineRow.setMarginRate(XxcsoQuoteConstants.RATE_MAX);
            }
            else
            {
              lineRow.setMarginRate(String.valueOf(PriceScale));
            }
          }
          catch ( NumberFormatException e )
          {
            XxcsoUtils.debug(txn, "NumberFormatException");
          }
        }
        break;
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }
/* 20090616_abe_T1_1257 START*/
    //lineVo.first();
/* 20090616_abe_T1_1257 END*/
/* 20090910_abe_0001331 START*/
    try{
      BigDecimal line_row = new BigDecimal(lineVo.getCurrentRowIndex()+1);
      BigDecimal line_size =new BigDecimal(
                    txn.getProfile("XXCSO1_VIEW_SIZE_017_A02_01".toString()));

      line_row = line_row.divide(line_size,0,BigDecimal.ROUND_UP);
      lineVo.scrollToRangePage((line_row.intValue()));
    }
    catch ( NumberFormatException e )
    {
      lineVo.first();
    }
/* 20090910_abe_0001331 END*/


    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���l�̎Z�o����
   *****************************************************************************
   */
  public void handleValidateReference()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    XxcsoReferenceQuotationPriceVOImpl refVo 
      = getXxcsoReferenceQuotationPriceVO1();
    if ( refVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReferenceQuotationPriceVO1");
    }

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      // �Q�ƑΏۂ̃f�[�^�����݂��Ă��邩���m�F
      refVo.initQuery(lineRow.getInventoryItemId().toString()
                     ,headerRow.getAccountNumber());

      XxcsoReferenceQuotationPriceVORowImpl refRow
        = (XxcsoReferenceQuotationPriceVORowImpl)refVo.first();

      if ( refRow != null )
      {
        if ( lineRow.getQuotationPrice() == null &&
             refRow.getQuotationPrice() != null )
        {
          //�������ʂ�����ꍇ�͌��l��ݒ肷��
          lineRow.setQuotationPrice(refRow.getQuotationPrice().toString());
        }
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    lineVo.first();

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * �̔��p���ς̃X�e�[�^�X�X�V����
   * @see xxcso_017002j_pkg.set_sales_status
   *****************************************************************************
   */
  public void handleupdatesales()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    OracleCallableStatement stmt = null;

    //�X�e�[�^�X�X�V�p�v���V�[�W����call
    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append(" xxcso_017002j_pkg.set_sales_status(");
      sql.append(" :1);");
      sql.append("END;");

      XxcsoUtils.debug(txn, "execute = " + sql.toString());

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);
      // �p�����[�^�̐ݒ�
      stmt.setNUMBER(1, headerRow.getReferenceQuoteHeaderId());
      
      XxcsoUtils.debug(
        txn, "ReferenceQuoteHeaderId:"+headerRow.getReferenceQuoteHeaderId());

        XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
        XxcsoUtils.debug(txn, "execute stored end");

    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }

    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * ���Ϗ��i�����p�j�\�z����
   * XxcsoQuoteHeadersFullVORowImpl.setReferenceQuoteHeaderId���Call����܂��B
   * @param referenceQuoteHeaderId ���σw�b�_�[ID�i�̔���p�j
   * @see itoen.oracle.apps.xxcso.xxcso017002j.server.XxcsoQuoteHeadersFullVORowImpl.setReferenceQuoteHeaderId()
   *****************************************************************************
   */
  protected void buildQuoteStore(
    Number referenceQuoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo
      = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeadersFullVO1"
        );
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo
      = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteLinesStoreFullVO1"
        );
    }

    XxcsoQuoteHeaderSalesSumVOImpl salesHeaderVo
      = getXxcsoQuoteHeaderSalesSumVO1();
    if ( salesHeaderVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteHeaderSalesSumVO1"
        );
    }

    XxcsoQuoteLineSalesSumVOImpl salesLineVo
      = getXxcsoQuoteLineSalesSumVO1();
    if ( salesLineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoQuoteLineSalesSumVO1"
        );
    }

    salesHeaderVo.initQuery(referenceQuoteHeaderId);

    XxcsoQuoteHeaderSalesSumVORowImpl salesHeaderRow
      = (XxcsoQuoteHeaderSalesSumVORowImpl)salesHeaderVo.first();
    if ( salesHeaderRow == null )
    {
      return;
    }

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    headerRow.setStoreName(salesHeaderRow.getStoreName());
    headerRow.setSalesUnitType(salesHeaderRow.getUnitType());
    headerRow.setReferenceQuoteNumber(salesHeaderRow.getQuoteNumber());
    
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();
    while ( lineRow != null )
    {
      lineVo.removeCurrentRow();
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    salesLineVo.initQuery(referenceQuoteHeaderId);
    XxcsoQuoteLineSalesSumVORowImpl salesLineRow
      = (XxcsoQuoteLineSalesSumVORowImpl)salesLineVo.first();

    while ( salesLineRow != null )
    {
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      lineRow.setQuoteLineId(salesLineRow.getQuoteLineId());
      lineRow.setInventoryItemId(salesLineRow.getInventoryItemId());
      lineRow.setInventoryItemCode(salesLineRow.getInventoryItemCode());
      lineRow.setItemShortName(salesLineRow.getItemShortName());
      lineRow.setQuoteDiv(salesLineRow.getQuoteDiv());
/* 20090616_abe_T1_1257 START*/
      lineRow.setCaseIncNum(salesLineRow.getCaseIncNum());
      lineRow.setBowlIncNum(salesLineRow.getBowlIncNum());
/* 20090616_abe_T1_1257 END*/
      lineRow.setUsuallyDelivPrice(salesLineRow.getUsuallyDelivPrice());
      lineRow.setThisTimeDelivPrice(salesLineRow.getThisTimeDelivPrice());
      lineRow.setQuoteStartDate(salesLineRow.getQuoteStartDate());
      lineRow.setQuoteEndDate(salesLineRow.getQuoteEndDate());
      lineRow.setSelectFlag("N");

      salesLineRow = (XxcsoQuoteLineSalesSumVORowImpl)salesLineVo.next();
    }

    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �m��`�F�b�N����
   *****************************************************************************
   */
  private void validateFixed()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // ���̓`�F�b�N���s���܂��B
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }
    
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
    XxcsoQtApTaxRateVOImpl taxVo = getXxcsoQtApTaxRateVO1();
    if ( taxVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQtApTaxRateVO1");
    }
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End

    errorList = validateHeader(errorList);

    /* 20090518_abe_T1_1023 START*/
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    /* 20090518_abe_T1_1023 END*/

    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
    XxcsoQtApTaxRateVORowImpl taxRow
      = (XxcsoQtApTaxRateVORowImpl)taxVo.first();
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End

    /* 20090324_abe_�ۑ�77 START*/
    //�v���t�@�C���̎擾
    int period_Day = 0;
    try{
      period_Day =  Integer.parseInt(txn.getProfile(XxcsoQuoteConstants.PERIOD_DAY));
    }
    catch ( NumberFormatException e )
    {
      period_Day = 0;
    }
    /* 20090324_abe_�ۑ�77 END*/
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add Start
    //�v���t�@�C��(XXCSO:�ُ�}�[�W����)�̎擾
    String err_Margin_Rate_Str = txn.getProfile(XxcsoQuoteConstants.ERR_MARGIN_RATE);
    double err_Margin_Rate = 0;
    if ( err_Margin_Rate_Str == null || "".equals(err_Margin_Rate_Str.trim()) )
    {
      //�擾�ł��Ȃ�(NULL)�ꍇ�G���[��\�����I��
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoQuoteConstants.ERR_MARGIN_RATE
        );
    }
    try{
      err_Margin_Rate = Double.parseDouble(err_Margin_Rate_Str);
    }
    catch ( NumberFormatException e )
    {
      //���l�ɕϊ��ł��Ȃ��ꍇ�G���[��\�����I��
      throw
        XxcsoMessage.createProfileOptionValueError(
          XxcsoQuoteConstants.ERR_MARGIN_RATE
         ,err_Margin_Rate_Str
        );
    }
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add End
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
    //�����ŗ��̑��݃`�F�b�N
    double taxrate = -1;
    if ( taxRow != null )
    {
      taxrate = taxRow.getApTaxRate().doubleValue();
    }
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
    int index = 0;
    while ( lineRow != null )
    {
      if( "Y".equals(lineRow.getSelectFlag()) )
      {
        index++;
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Del Start
///* 20090616_abe_T1_1257 START*/
//        handleMarginCalculation(
//          lineRow.getQuoteLineId().toString()
//        );
///* 20090616_abe_T1_1257 END*/
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Del End
        validateLine(
          errorList
         ,lineRow
         ,index
        );

        validateFixedLine(
          errorList
         /* 20090518_abe_T1_1023 START*/
         ,headerRow
         /* 20090518_abe_T1_1023 END*/
         ,lineRow
         ,index
         /* 20090324_abe_�ۑ�77 START*/
         ,period_Day
         /* 20090324_abe_�ۑ�77 END*/
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
         ,taxrate
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add Start
         ,err_Margin_Rate
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add End
        );
      }
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }
/* 20090910_abe_0001331 START*/
    lineVo.first();
/* 20090910_abe_0001331 END*/

    if ( index == 0 )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00451);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���σw�b�_�[���ڂ̃`�F�b�N����
   * @param errorList �G���[���X�g
   *****************************************************************************
   */
  private List validateHeader(
    List errorList
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // ���̓`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    ///////////////////////////////////
    // �l���؁i���σw�b�_�[�j
    ///////////////////////////////////
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // �Q�Ɨp���ϔԍ�
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getReferenceQuoteNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REFERENCE_QUOTE_NUMBER
         ,0
        );

    // ���s��
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getPublishDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PUBLISH_DATE
         ,0
        );

    // �ڋq�R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,headerRow.getAccountNumber()
         ,XxcsoQuoteConstants.TOKEN_VALUE_ACCOUNT_NUMBER
         ,0
        );

    // �[���ꏊ
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getDelivPlace()
         ,XxcsoQuoteConstants.TOKEN_VALUE_DELIV_PLACE
         ,0
        );

    // �x������
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getPaymentCondition()
         ,XxcsoQuoteConstants.TOKEN_VALUE_PAYMENT_CONDITION
         ,0
        );

    // ���Ϗ���o�於
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getQuoteSubmitName()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_SUBMIT_NAME
         ,0
        );

    // ���L����
    errorList
      = util.checkIllegalString(
          errorList
         ,headerRow.getSpecialNote()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SPECIAL_NOTE
         ,0
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * ���ϖ��׍��ڂ̃`�F�b�N�����iDB�o�^�p�j
   * @param errorList     �G���[���X�g
   * @param lineRow       ���ϖ��׍s�C���X�^���X
   * @param index         �Ώۍs
   *****************************************************************************
   */
  private List validateLine(
    List                              errorList
   ,XxcsoQuoteLinesStoreFullVORowImpl lineRow
   ,int                               index
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // ���̓`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    ///////////////////////////////////
    // �l���؁i���ϖ��ׁj
    ///////////////////////////////////
    //���i��null�̏ꍇ�ӂ́u0�v�ɒu��������
/* 20090723_abe_0000806 START*/
    //if ( lineRow.getQuotationPrice() == null )
    //{
    //  lineRow.setQuotationPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getSalesDiscountPrice() == null )
    //{
    //  lineRow.setSalesDiscountPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getUsuallNetPrice() == null )
    //{
    //  lineRow.setUsuallNetPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}

    //if ( lineRow.getThisTimeNetPrice() == null )
    //{
    //  lineRow.setThisTimeNetPrice(XxcsoQuoteConstants.DEF_PRICE);
    //}
/* 20090723_abe_0000806 END*/

    // ���l
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getQuotationPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTATION_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // ����l��
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getSalesDiscountPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_SALES_DISCOUNT_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // �ʏ�NET���i
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallNetPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // ����NET���i
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeNetPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // ���я�
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getLineOrder()
         ,XxcsoQuoteConstants.TOKEN_VALUE_LINE_ORDER
         ,0
         ,2
         ,true
         ,false
         ,false
         ,index
        );

    // ���l
    errorList
      = util.checkIllegalString(
          errorList
         ,lineRow.getRemarks()
         ,XxcsoQuoteConstants.TOKEN_VALUE_REMARKS
         ,index
        );

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }
  
  /*****************************************************************************
   * ���ϖ��׍��ڂ̃`�F�b�N�����i�m��`�F�b�N�j
   * @param errorList        �G���[���X�g
   * @param headerRow        ���σw�b�_�s�C���X�^���X
   * @param lineRow          ���ϖ��׍s�C���X�^���X
   * @param index            �Ώۍs
   * @param period_Daye      �v���t�@�C���l��20090324_abe_�ۑ�77 ADD
   * @param taxrate          �ŗ�
   * @param err_Margin_Rate  �ُ�}�[�W����
   *****************************************************************************
   */
  private List validateFixedLine(
    List                              errorList
   /* 20090518_abe_T1_1023 START*/
   ,XxcsoQuoteHeadersFullVORowImpl  headerRow
   /* 20090518_abe_T1_1023 END*/
   ,XxcsoQuoteLinesStoreFullVORowImpl lineRow
   ,int                               index
   /* 20090324_abe_�ۑ�77 START*/
   ,int                               period_Daye
   /* 20090324_abe_�ۑ�77 END*/
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
   ,double                            taxrate
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add Start
   ,double                            err_Margin_Rate
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add End
  )
  {
    OADBTransaction txn = getOADBTransaction();
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
    double taxratecul = 0;
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");      
    }

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add Start
    //�}�[�W�����̌v�Z   
    handleMarginCalculation(
      lineRow.getQuoteLineId().toString()
    );
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add End

    // �K�{�`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

/* 2009.07.30 D.Abe 0000806�Ή� START */
    // ���l
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuotationPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTATION_PRICE
         ,index
        );
/* 2009.07.30 D.Abe 0000806�Ή� END */

    // ���ԁi�J�n�j
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteStartDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_START_DATE
         ,index
        );

    // ���ԃ`�F�b�N
    if ( lineRow.getQuoteStartDate() != null )
    {
      Date currentDate = new Date(initRow.getCurrentDate());
      /* 20090324_abe_�ۑ�77 START*/
      //Date limitDate = (Date)currentDate.addJulianDays(-30, 0);
      Date limitDate = (Date)currentDate.addJulianDays(-period_Daye, 0);

      // �V�X�e�����t���30���O�܂œ��͉\�y�폜�z
      // �V�X�e�����t���v���t�@�C���l���O�܂œ��͉\
      /* 20090324_abe_�ۑ�77 END*/
      if ( lineRow.getQuoteStartDate().compareTo(limitDate) < 0 )
      {
        XxcsoUtils.debug(txn, limitDate);

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00463
             /* 20090324_abe_�ۑ�77 START*/
             ,XxcsoConstants.TOKEN_PERIOD
             ,String.valueOf(period_Daye)
             /* 20090324_abe_�ۑ�77 END*/
             ,XxcsoConstants.TOKEN_INDEX
             ,String.valueOf(index)
            );
        errorList.add(error);
      }

      // ���ԁi�J�n�j�����ԁi�I���j��薢���ł͂Ȃ����`�F�b�N
      if ( lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
      {
        XxcsoUtils.debug(txn, limitDate);

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00499
             ,XxcsoConstants.TOKEN_INDEX
             ,String.valueOf(index)
            );
        errorList.add(error);
      }
    }
    
/* 20090616_abe_T1_1257 START*/
/* 20090723_abe_0000806 START*/
    // �����̃`�F�b�N
    //double caseincnum      = lineRow.getCaseIncNum().doubleValue();
    //double bowlincnum      = lineRow.getBowlIncNum().doubleValue();

    //if(((caseincnum == 0) &&
    //    (headerRow.getUnitType().equals("2"))) ||
    //   ((bowlincnum == 0) &&
    //    (headerRow.getUnitType().equals("3")))
    //  )
    //{
    //    OAException error
    //      = XxcsoMessage.createErrorMessage(
    //          XxcsoConstants.APP_XXCSO1_00574,
    //          XxcsoConstants.TOKEN_INDEX,
    //          String.valueOf(index)
    //        );
    //    errorList.add(error);
    //}
    //else
    //{
/* 20090723_abe_0000806 END*/
    // �ʏ킩�����̏ꍇ�́ANET���i�̌�������`�F�b�N
    if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) ||
       XxcsoQuoteConstants.QUOTE_DIV_BARGAIN.equals(lineRow.getQuoteDiv())
       )
    {
/* 20090723_abe_0000806 START*/
      // �ʏ�NET���i�̕K�{�`�F�b�N
      if(lineRow.getUsuallNetPrice() == null) 
      {
        errorList
          = util.requiredCheck(
              errorList
             ,lineRow.getUsuallNetPrice()
             ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
             ,index
            );
      }
      else
      {
        // �����̃`�F�b�N
        double caseincnum      = lineRow.getCaseIncNum().doubleValue();
        double bowlincnum      = lineRow.getBowlIncNum().doubleValue();

        if(((caseincnum == 0) &&
            (headerRow.getUnitType().equals("2"))) ||
           ((bowlincnum == 0) &&
            (headerRow.getUnitType().equals("3")))
          )
        {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00574,
                  XxcsoConstants.TOKEN_INDEX,
                  String.valueOf(index)
                );
            errorList.add(error);
        }
        else
        {
/* 20090723_abe_0000806 END*/
          String usuallNetPriceRep 
            = lineRow.getUsuallNetPrice().replaceAll(",", "");
/* 20090723_abe_0000806 START*/
          //String thisTimeNetPriceRep 
          //  = lineRow.getThisTimeNetPrice().replaceAll(",", "");
/* 20090723_abe_0000806 END*/
          /* 20090518_abe_T1_1023 START*/
          String unittype        = headerRow.getUnitType();
          //double caseincnum      = lineRow.getCaseIncNum().doubleValue();
          //double bowlincnum      = lineRow.getBowlIncNum().doubleValue();
          /* 20090518_abe_T1_1023 END*/      
/* 20090616_abe_T1_1257 END*/
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
          //�ŋ敪��"2"(�ō����i)�̏ꍇ�A�����ŗ��̃`�F�b�N
          if (headerRow.getDelivPriceTaxType().equals("2"))
          {
            //��������ł��擾�ł��Ă���ꍇ
            if (taxrate != -1)
            {
              //�����̐ŗ���ݒ�
              taxratecul = taxrate;
            }
            else
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00613,
                    XxcsoConstants.TOKEN_COLUMN,
                    XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
          }
          //�ŋ敪��"1"(�Ŕ����i)�̏ꍇ
          else
          {
            //�c�ƌ����Ń`�F�b�N����ׁA�ŗ���1��ݒ�
            taxratecul = 1;
          }
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod Start
//          /* 20091221_abe_E_�{�ғ�_00535 START*/
//          if (lineRow.getBusinessPrice() != null)
          if ((lineRow.getBusinessPrice() != null) &&
              (taxrate != -1)
             )
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod End
          {
          /* 20091221_abe_E_�{�ғ�_00535 END*/
            double businessPrice = lineRow.getBusinessPrice().doubleValue();
            try
            {
              double usuallNetPrice  = Double.parseDouble(usuallNetPriceRep);

              // �ʏ�NET���i
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod Start
//              /* 20090518_abe_T1_1023 START*/
//              if ( (usuallNetPrice <= businessPrice && unittype.equals("1") ) ||
//                   ((usuallNetPrice / caseincnum <= businessPrice ||
//                    caseincnum == 0) && unittype.equals("2") ) || 
//                   ((usuallNetPrice / bowlincnum <= businessPrice ||
//                    bowlincnum == 0) && unittype.equals("3"))
//                 )
//              //if ( usuallNetPrice <= businessPrice )
              if ( (usuallNetPrice <= businessPrice  * taxratecul && unittype.equals("1") ) ||
                   ((usuallNetPrice / caseincnum <= businessPrice * taxratecul ||
                    caseincnum == 0) && unittype.equals("2") ) || 
                   ((usuallNetPrice / bowlincnum <= businessPrice * taxratecul ||
                    bowlincnum == 0) && unittype.equals("3"))
                 )
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod End
              /* 20090518_abe_T1_1023 END*/
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00498,
                      XxcsoConstants.TOKEN_COLUMN,
                      XxcsoQuoteConstants.TOKEN_VALUE_USUALLY,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
            catch ( NumberFormatException e )
            {
              XxcsoUtils.debug(txn, "NumberFormatException");
            }
          /* 20091221_abe_E_�{�ғ�_00535 START*/
          }
          /* 20091221_abe_E_�{�ғ�_00535 END*/
/* 20090723_abe_0000806 START*/
        }
      }
      // ����X�[���i���ݒ肳��Ă���ꍇ
      if(lineRow.getThisTimeDelivPrice() != null) 
      {
        // ����NET���i�̕K�{�`�F�b�N
        if(lineRow.getThisTimeNetPrice() == null)
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getThisTimeNetPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
               ,index
              );
        }
        else
        {
          // �����̃`�F�b�N
          double caseincnum      = lineRow.getCaseIncNum().doubleValue();
          double bowlincnum      = lineRow.getBowlIncNum().doubleValue();
          if(((caseincnum == 0) &&
              (headerRow.getUnitType().equals("2"))) ||
             ((bowlincnum == 0) &&
              (headerRow.getUnitType().equals("3")))
            )
          {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00574,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
          }
          else
          {
            String thisTimeNetPriceRep 
              = lineRow.getThisTimeNetPrice().replaceAll(",", "");
            String unittype        = headerRow.getUnitType();
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add Start
            //�ŗ�������
            taxratecul = 0;
            //�ŋ敪��"2"(�ō����i)�̏ꍇ�A�����ŗ��̃`�F�b�N
            if(headerRow.getDelivPriceTaxType().equals("2"))
            {
              //��������ł��擾�ł��Ă���ꍇ
              if(taxrate != -1)
              {
                //�����̉����ŗ���ݒ�
                taxratecul = taxrate;
              }
              else
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00613,
                      XxcsoConstants.TOKEN_COLUMN,
                      XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
            //�ŋ敪��"1"(�Ŕ����i)�̏ꍇ
            else
            {
              //�c�ƌ����Ń`�F�b�N����ׁA�ŗ���1��ݒ�
              taxratecul = 1;
            }
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Add End
            /* 20091221_abe_E_�{�ғ�_00535 START*/
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod Start
//            if (lineRow.getBusinessPrice() != null)
            if ((lineRow.getBusinessPrice() != null) &&
                (taxrate != -1)
               )
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod End
            {
            /* 20091221_abe_E_�{�ғ�_00535 END*/
              double businessPrice = lineRow.getBusinessPrice().doubleValue();
/* 20090723_abe_0000806 END*/
              try
              {
                double thisTimeNetPrice = Double.parseDouble(thisTimeNetPriceRep);

                // ����NET���i
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod Start
//                /* 20090518_abe_T1_1023 START*/
//                if ( (thisTimeNetPrice <= businessPrice && unittype.equals("1") ) ||
//                     ((thisTimeNetPrice / caseincnum <= businessPrice ||
//                      caseincnum == 0) && unittype.equals("2") ) || 
//                     ((thisTimeNetPrice / bowlincnum <= businessPrice ||
//                      bowlincnum == 0) && unittype.equals("3"))
//                   )
//                //if ( thisTimeNetPrice <= businessPrice )
//                /* 20090518_abe_T1_1023 END*/
                if ( (thisTimeNetPrice <= businessPrice * taxratecul && unittype.equals("1") ) ||
                     ((thisTimeNetPrice / caseincnum <= businessPrice * taxratecul ||
                      caseincnum == 0) && unittype.equals("2") ) || 
                     ((thisTimeNetPrice / bowlincnum <= businessPrice * taxratecul ||
                      bowlincnum == 0) && unittype.equals("3"))
                   )
// 2011-05-17 Ver1.11 [E_�{�ғ�_02500] Mod End
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00498,
                        XxcsoConstants.TOKEN_COLUMN,
                        XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              catch ( NumberFormatException e )
              {
                XxcsoUtils.debug(txn, "NumberFormatException");
              }
            /* 20091221_abe_E_�{�ғ�_00535 START*/
            }
            /* 20091221_abe_E_�{�ғ�_00535 END*/
/* 20090723_abe_0000806 START*/
          }
/* 20090723_abe_0000806 END*/
        }
/* 20090723_abe_0000806 START*/
      }
/* 20090723_abe_0000806 END*/
/* 20090616_abe_T1_1257 START*/
    }
/* 20090616_abe_T1_1257 END*/
/* 20090723_abe_0000806 START*/
    // �V�K��������������̏ꍇ
    if ( XxcsoQuoteConstants.QUOTE_DIV_INTRO.equals(lineRow.getQuoteDiv()) ||
         XxcsoQuoteConstants.QUOTE_DIV_COST.equals(lineRow.getQuoteDiv())
       )
    {
      // �ʏ�NET���i�̕K�{�`�F�b�N
      if(lineRow.getUsuallNetPrice() == null) 
      {
        errorList
          = util.requiredCheck(
              errorList
             ,lineRow.getUsuallNetPrice()
             ,XxcsoQuoteConstants.TOKEN_VALUE_USUALL_NET_PRICE
             ,index
            );
      }
      // ����X�[���i���ݒ肳��Ă���ꍇ
      if(lineRow.getThisTimeDelivPrice() != null) 
      {
        // ����NET���i�̕K�{�`�F�b�N
        if(lineRow.getThisTimeNetPrice() == null)
        {
          errorList
            = util.requiredCheck(
                errorList
               ,lineRow.getThisTimeNetPrice()
               ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_NET_PRICE
               ,index
              );
        }
      }
    }
/* 20090723_abe_0000806 END*/
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add Start
    //�ُ�}�[�W�����ȏ�̏ꍇ�G���[
    if ( err_Margin_Rate <= Double.parseDouble(lineRow.getMarginRate()) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00617
           ,XxcsoConstants.TOKEN_MARGIN_RATE
           ,String.valueOf(err_Margin_Rate)
           ,XxcsoConstants.TOKEN_INDEX
           ,String.valueOf(index)
          );
        errorList.add(error);       
    }
// 2011-11-14 Ver1.12 [E_�{�ғ�_08312] Add End
    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

/* 20090723_abe_0000806 START*/
  /*****************************************************************************
   * �≮���׍s�\�������v���p�e�B�ݒ�
   *****************************************************************************
   */
  public void setLineProperty()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    XxcsoReferenceQuotationPriceVOImpl refVo 
      = getXxcsoReferenceQuotationPriceVO1();
    if ( refVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReferenceQuotationPriceVO1");
    }

      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

      XxcsoQuoteLinesStoreFullVORowImpl lineRow
        = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      // ����X�[���i���ݒ�Ȃ��̏ꍇ�A����NET���i���g�p�s��
      if (lineRow.getThisTimeDelivPrice() == null)
      {
        lineRow.setThisTimeDelivReadOnly(Boolean.TRUE);
      }
      else
      {
        lineRow.setThisTimeDelivReadOnly(Boolean.FALSE);
      }

      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    lineVo.first();

    XxcsoUtils.debug(txn, "[END]");

  }

/* 20090723_abe_0000806 END*/

// 2011-04-18 v1.10 T.Yoshimoto Add Start E_�{�ғ�_01373
  /*****************************************************************************
   * �ʏ�NET���i�擾����
   *****************************************************************************
   */
  public void handleUsuallNetPriceButton()
  {

    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //�C���X�^���X�擾
    ////////////////

    // ���σw�b�_VO�C���X�^���X�擾
    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    // ���ϖ���VO�C���X�^���X�擾
    XxcsoQuoteLinesStoreFullVOImpl lineVo = getXxcsoQuoteLinesStoreFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesStoreFullVO1");
    }

    // �ʏ�NET���iVO�C���X�^���X�擾
    XxcsoUsuallNetPriceVOImpl usuallNetPriceVo = getXxcsoUsuallNetPriceVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoUsuallNetPriceVO1");
    }

    // ���σw�b�_VO��1�s�ڂ��擾
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    
    // ���ϖ���VO��1�s�ڂ��擾
    XxcsoQuoteLinesStoreFullVORowImpl lineRow
      = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {

      if ( "Y".equals(lineRow.getSelectFlag()) )
      {

        // �ʏ�NET���i�̌������s
        usuallNetPriceVo.initQuery(
          headerRow.getAccountNumber(),    // �ڋq�R�[�h
          lineRow.getInventoryItemId(),    // �i��ID
          lineRow.getUsuallyDelivPrice()   // �ʏ�X�[���i
        );

        // �ʏ�NET���i�擾
        XxcsoUsuallNetPriceVORowImpl usuallNetPriceRow
          = (XxcsoUsuallNetPriceVORowImpl)usuallNetPriceVo.first();

        //�ʏ�NET���i���擾�ł����ꍇ
        if ( usuallNetPriceRow != null )
        {

          // �擾�����ʏ�X�[���i��ݒ�
          lineRow.setUsuallNetPrice(usuallNetPriceRow.getUsuallNetPrice());
        }
      }

      // ���s���擾
      lineRow = (XxcsoQuoteLinesStoreFullVORowImpl)lineVo.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");

  }
// 2011-04-18 v1.10 T.Yoshimoto Add End E_�{�ғ�_01373

  /*****************************************************************************
   * �{�^�������_�����O����
   *****************************************************************************
   */
  private void initRender()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoQuoteStoreInitVOImpl initVo = getXxcsoQuoteStoreInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteStoreInitVO1");
    }
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    XxcsoQuoteStoreInitVORowImpl initRow
      = (XxcsoQuoteStoreInitVORowImpl)initVo.first();

    initRow.setCopyCreateButtonRender(Boolean.FALSE);
    initRow.setInvalidityButtonRender(Boolean.FALSE);
    initRow.setApplicableButtonRender(Boolean.FALSE);
    initRow.setRevisionButtonRender(Boolean.FALSE);
    initRow.setFixedButtonRender(Boolean.FALSE);
    initRow.setQuoteSheetPrintButtonRender(Boolean.FALSE);
    initRow.setCsvCreateButtonRender(Boolean.FALSE);

    String status = headerRow.getStatus();
    if ( status == null || "".equals(status.trim()) )
    {
      initRow.setApplicableButtonRender(Boolean.TRUE);
    }
    else
    {
      /* 20090324_abe_T1_0138 START*/
      if ( XxcsoQuoteConstants.QUOTE_INIT.equals(status) )
      {
        initRow.setApplicableButtonRender(Boolean.TRUE);      
      }
      /* 20090324_abe_T1_0138 END*/
      if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setApplicableButtonRender(Boolean.TRUE);
        initRow.setRevisionButtonRender(Boolean.TRUE);
        initRow.setFixedButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_INVALIDITY.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_OLD.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
      }
      if ( XxcsoQuoteConstants.QUOTE_FIXATION.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
        initRow.setInvalidityButtonRender(Boolean.TRUE);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * CSV�s�쐬����
   *****************************************************************************
   */
  private StringBuffer createCsvStatement(
    StringBuffer buffer
   ,String       value
   ,boolean      endFlag
  )
  {
    /* 20090413_abe_T1_0299 START*/
    if ( value == null )
    {
      value = "";
    }
    /* 20090413_abe_T1_0299 END*/
    buffer.append("\"");
    buffer.append(value);
    buffer.append("\"");

    if ( endFlag )
    {
      buffer.append("\r\n");
    }
    else
    {
      buffer.append(",");
    }

    return buffer;
  }

  /*****************************************************************************
   * �R�~�b�g����
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���[���o�b�N����
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    if ( getTransaction().isDirty() )
    {
      // ���[���o�b�N���s���܂��B
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");

  }


  /**
   * 
   * Container's getter for XxcsoQuoteHeadersFullVO1
   */
  public XxcsoQuoteHeadersFullVOImpl getXxcsoQuoteHeadersFullVO1()
  {
    return (XxcsoQuoteHeadersFullVOImpl)findViewObject("XxcsoQuoteHeadersFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLinesStoreFullVO1
   */
  public XxcsoQuoteLinesStoreFullVOImpl getXxcsoQuoteLinesStoreFullVO1()
  {
    return (XxcsoQuoteLinesStoreFullVOImpl)findViewObject("XxcsoQuoteLinesStoreFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreVL1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017002j.server", "XxcsoQuoteStoreRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderSalesSumVO1
   */
  public XxcsoQuoteHeaderSalesSumVOImpl getXxcsoQuoteHeaderSalesSumVO1()
  {
    return (XxcsoQuoteHeaderSalesSumVOImpl)findViewObject("XxcsoQuoteHeaderSalesSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLineSalesSumVO1
   */
  public XxcsoQuoteLineSalesSumVOImpl getXxcsoQuoteLineSalesSumVO1()
  {
    return (XxcsoQuoteLineSalesSumVOImpl)findViewObject("XxcsoQuoteLineSalesSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteStoreInitVO1
   */
  public XxcsoQuoteStoreInitVOImpl getXxcsoQuoteStoreInitVO1()
  {
    return (XxcsoQuoteStoreInitVOImpl)findViewObject("XxcsoQuoteStoreInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteStatusLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteStatusLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteStatusLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoDelivPriceTaxTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoDelivPriceTaxTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDelivPriceTaxTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUnitPriceSalesLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceSalesLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceSalesLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUnitPriceStoreLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceStoreLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceStoreLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoCsvDownVO1
   */
  public XxcsoCsvDownVOImpl getXxcsoCsvDownVO1()
  {
    return (XxcsoCsvDownVOImpl)findViewObject("XxcsoCsvDownVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoQuoteDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoQuoteDivLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeadersFullVO2
   */
  public XxcsoQuoteHeadersFullVOImpl getXxcsoQuoteHeadersFullVO2()
  {
    return (XxcsoQuoteHeadersFullVOImpl)findViewObject("XxcsoQuoteHeadersFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLinesStoreFullVO2
   */
  public XxcsoQuoteLinesStoreFullVOImpl getXxcsoQuoteLinesStoreFullVO2()
  {
    return (XxcsoQuoteLinesStoreFullVOImpl)findViewObject("XxcsoQuoteLinesStoreFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreVL2
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreVL2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderStoreSumVO1
   */
  public XxcsoQuoteHeaderStoreSumVOImpl getXxcsoQuoteHeaderStoreSumVO1()
  {
    return (XxcsoQuoteHeaderStoreSumVOImpl)findViewObject("XxcsoQuoteHeaderStoreSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteLineStoreSumVO1
   */
  public XxcsoQuoteLineStoreSumVOImpl getXxcsoQuoteLineStoreSumVO1()
  {
    return (XxcsoQuoteLineStoreSumVOImpl)findViewObject("XxcsoQuoteLineStoreSumVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineStoreSumVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineStoreSumVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineStoreSumVL1");
  }

  /**
   * 
   * Container's getter for XxcsoCsvQueryVO1
   */
  public XxcsoCsvQueryVOImpl getXxcsoCsvQueryVO1()
  {
    return (XxcsoCsvQueryVOImpl)findViewObject("XxcsoCsvQueryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoReferenceQuotationPriceVO1
   */
  public XxcsoReferenceQuotationPriceVOImpl getXxcsoReferenceQuotationPriceVO1()
  {
    return (XxcsoReferenceQuotationPriceVOImpl)findViewObject("XxcsoReferenceQuotationPriceVO1");
  }

// 2011-04-18 v1.10 T.Yoshimoto Add Start E_�{�ғ�_01373
  /**
   * 
   * Container's getter for XxcsoUsuallNetPriceVO1
   */
  public XxcsoUsuallNetPriceVOImpl getXxcsoUsuallNetPriceVO1()
  {
    return (XxcsoUsuallNetPriceVOImpl)findViewObject("XxcsoUsuallNetPriceVO1");
  }

  /**
   * 
   * Container's getter for XxcsoQtApTaxRateVO1
   */
  public XxcsoQtApTaxRateVOImpl getXxcsoQtApTaxRateVO1()
  {
    return (XxcsoQtApTaxRateVOImpl)findViewObject("XxcsoQtApTaxRateVO1");
  }
// 2011-04-18 v1.10 T.Yoshimoto Add End E_�{�ғ�_01373
}