/*============================================================================
* �t�@�C���� : XxcsoQuoteSalesRegistAMImpl
* �T�v����   : �̔���p���ϓ��͉�ʃA�v���P�[�V�����E���W���[���N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-02 1.0  SCS�y���  �V�K�쐬
* 2009-02-24 1.1  SCS�y���  [CT1-010]�ʏ�X�[���i���o�{�^����ѱ�ďC��
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.BlobDomain;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.xxcso017001j.util.XxcsoQuoteConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;

/*******************************************************************************
 * �̔���p���ϓ��͉�ʂ̃A�v���P�[�V�����E���W���[���N���X
 * @author  SCS�y���
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQuoteSalesRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQuoteSalesRegistAMImpl()
  {
  }

  /*****************************************************************************
   * ���s�敪�u�Ȃ��v�̏ꍇ�̏���������
   * @param quoteHeaderId ���σw�b�_�[ID
   *****************************************************************************
   */
  public void initDetails(
    String quoteHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // �g�����U�N�V������������
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

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    initVo.executeQuery();
    
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    headerVo.initQuery(quoteHeaderId);
    headerVo.first();

    if (quoteHeaderId == null || "".equals(quoteHeaderId.trim()))
    {
      // ���σw�b�_�[
      XxcsoQuoteHeadersFullVORowImpl headerRow
        = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

      headerVo.insertRow(headerRow);

      // �{�^�������_�����O����
      initRender();
      
      // �����l�ݒ�
      headerRow.setQuoteType(
        XxcsoQuoteConstants.QUOTE_SALES
      );
      headerRow.setStatus(
        XxcsoQuoteConstants.QUOTE_INPUT
      );
      headerRow.setPublishDate(
        initRow.getCurrentDate()
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
        XxcsoQuoteConstants.DEF_DELIV_PLACE
      );
      headerRow.setPaymentCondition(
        XxcsoQuoteConstants.DEF_PAYMENT_CONDITION
      );
      headerRow.setDelivPriceTaxType(
        XxcsoQuoteConstants.DEF_DELIV_PRICE_TAX_TYPE
      );
      headerRow.setStorePriceTaxType(
        XxcsoQuoteConstants.DEF_STORE_PRICE_TAX_TYPE
      );
      headerRow.setUnitType(
        XxcsoQuoteConstants.DEF_UNIT_TYPE
      );
    }
    else
    {
      // �{�^�������_�����O����
      initRender();
    }
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���s�敪�uCOPY�v�̏ꍇ�̏���������
   * @param quoteHeaderId ���σw�b�_�[ID
   *****************************************************************************
   */
  public void initDetailsCopy(
    String quoteHeaderId
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

    // XxcsoQuoteHeadersFullVO2�C���X�^���X�̎擾
    XxcsoQuoteHeadersFullVOImpl headerVo2 = getXxcsoQuoteHeadersFullVO2();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO2");
    }

    // XxcsoQuoteLinesSalesFullVO1�C���X�^���X�̎擾
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteLinesSalesFullVO2�C���X�^���X�̎擾
    XxcsoQuoteLinesSalesFullVOImpl lineVo2 = getXxcsoQuoteLinesSalesFullVO2();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO2");
    }

    // XxcsoQuoteSalesInitVO1�C���X�^���X�̎擾
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    // ������
    headerVo.initQuery((String)null);
    headerVo.first();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);

    // ����
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeadersFullVORowImpl headerRow2
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo2.first();

    // �������pVO�̌���
    initVo.executeQuery();
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // �R�s�[
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
    );
    headerRow.setPublishDate(         
      initRow.getCurrentDate()          
    );
    headerRow.setAccountNumber(       
      headerRow2.getAccountNumber()      
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
      XxcsoQuoteConstants.QUOTE_INPUT   
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
    XxcsoQuoteLinesSalesFullVORowImpl lineRow2
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesSalesFullVORowImpl lineRow
        = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();

      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);
      
      // �R�s�[
      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
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
      lineRow.setRemarks(                
        lineRow2.getRemarks()                
      );
      lineRow.setLineOrder(              
        lineRow2.getLineOrder()              
      );
      lineRow.setBusinessPrice(          
        lineRow2.getBusinessPrice()          
      );

      // �R�s�[������ɏ�����
      lineRow.setQuoteStartDate(initRow.getCurrentDate());

      Date currentDate = new Date(initRow.getCurrentDate());
      
      if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
            lineRow.getQuoteDiv())
         )
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
      }
      else
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));        
      }

      lineRow2 = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    // �{�^�������_�����O����
    initRender();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���s�敪�uREVISION_UP�v�̏ꍇ�̏���������
   * @param quoteHeaderId ���σw�b�_�[ID
   *****************************************************************************
   */
  public void initDetailsRevisionUp(
    String quoteHeaderId
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

    // XxcsoQuoteHeadersFullVO2�C���X�^���X�̎擾
    XxcsoQuoteHeadersFullVOImpl headerVo2 = getXxcsoQuoteHeadersFullVO2();
    if ( headerVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO2");
    }

    // XxcsoQuoteLinesSalesFullVO1�C���X�^���X�̎擾
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteLinesSalesFullVO2�C���X�^���X�̎擾
    XxcsoQuoteLinesSalesFullVOImpl lineVo2 = getXxcsoQuoteLinesSalesFullVO2();
    if ( lineVo2 == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO2");
    }

    // XxcsoQuoteSalesInitVO1�C���X�^���X�̎擾
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    // ������
    headerVo.initQuery((String)null);
    headerVo.first();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.createRow();

    // ����
    headerVo2.initQuery(quoteHeaderId);
    XxcsoQuoteHeadersFullVORowImpl headerRow2
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo2.first();

    headerVo.insertRow(headerRow);

    // �������pVO�̌���
    initVo.executeQuery();
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // ���������擾
    int attrNum = headerVo.getAttributeCount();

     // �R�s�[
    headerRow.setQuoteType(
      headerRow2.getQuoteType()
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
      XxcsoQuoteConstants.QUOTE_INPUT   
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

    // ���茳�̃X�e�[�^�X�����łɂ���
    headerRow2.setStatus(XxcsoQuoteConstants.QUOTE_OLD);
    
    // ���ׂ̃R�s�[
    XxcsoQuoteLinesSalesFullVORowImpl lineRow2
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.first();
    
    while ( lineRow2 != null )
    {
      XxcsoQuoteLinesSalesFullVORowImpl lineRow
        = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();
      
      lineVo.last();
      lineVo.next();
      lineVo.insertRow(lineRow);

      // �R�s�[
      lineRow.setInventoryItemId(        
        lineRow2.getInventoryItemId()        
      );
      lineRow.setInventoryItemCode(      
        lineRow2.getInventoryItemCode()      
      );
      lineRow.setQuoteDiv(               
        lineRow2.getQuoteDiv()               
      );
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
      lineRow.setRemarks(                
        lineRow2.getRemarks()                
      );
      lineRow.setLineOrder(              
        lineRow2.getLineOrder()              
      );
      lineRow.setBusinessPrice(          
        lineRow2.getBusinessPrice()          
      );

      // �R�s�[������ɏ�����
      lineRow.setQuoteStartDate(initRow.getCurrentDate());
      Date currentDate = new Date(initRow.getCurrentDate());

      if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
            lineRow.getQuoteDiv())
         )
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
      }
      else
      {
        lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));        
      }
      
      lineRow2 = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo2.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    // �{�^�������_�����O����
    initRender();

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
      
    // *****�X�[���i�ŋ敪
    XxcsoLookupListVOImpl delivPriceTaxTypeLookupVo =
      getXxcsoDelivPriceTaxTypeLookupVO();
    if (delivPriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDelivPriceTaxDivLookupVO");
    }
    // lookup�̏�����
    delivPriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");
      
    // *****�������i�ŋ敪
    XxcsoLookupListVOImpl storePriceTaxTypeLookupVo
        = getXxcsoStorePriceTaxTypeLookupVO();
    if (storePriceTaxTypeLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoStorePriceTaxTypLookupVO");
    }
    // lookup�̏�����
    storePriceTaxTypeLookupVo.initQuery("XXCSO1_TAX_DIVISION", "1");

    // *****�P���敪
    XxcsoLookupListVOImpl unitPriceDivLookupVo
        = getXxcsoUnitPriceDivLookupVO();
    if (unitPriceDivLookupVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoUnitPriceDivLookupVO");
    }
    // lookup�̏�����
    unitPriceDivLookupVo.initQuery("XXCSO1_UNIT_PRICE_DIVISION", "1");

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
   * ����{�^������������
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �ύX���e������������
    rollback();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �R�s�[�̍쐬�{�^������������
   * @return HashMap URL�p�����[�^
   *****************************************************************************
   */
  public HashMap handleCopyCreateButton(
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

   // ���ϔԍ�
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

    // �≮������p���ς̑��݃`�F�b�N���s��
    validateReference();
    
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
   *****************************************************************************
   */
  public HashMap handleApplicableButton(
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    // �≮������p���ς̑��݃`�F�b�N���s��
    validateReference();
    
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

    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // ���̓`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);
    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();
    // ���ϖ���
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

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

      //DB���f�`�F�b�N      
      errorList
        = validateLine(
            errorList
           ,lineRow
           ,index
          );

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

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
   *****************************************************************************
   */
  public HashMap handleRevisionButton(
    String returnPgName
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �≮������p���ς̑��݃`�F�b�N���s��
    validateReference();
    
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

   // ���ϔԍ�
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

    if ( getTransaction().isDirty() )
    {
      // �≮������p���ς̑��݃`�F�b�N���s��
      validateReference();
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

    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // ��ʍ��ڂ̓��̓`�F�b�N
    validateFixed();

    // �X�e�[�^�X���X�V
    headerRow.setStatus( XxcsoQuoteConstants.QUOTE_FIXATION );

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
      if ( getTransaction().isDirty() )
      {
        // �≮������p���ς̑��݃`�F�b�N���s��
        validateReference();
    
        // ��ʍ��ڂ̓��̓`�F�b�N
        validateFixed();

        // �ۑ����������s���܂��B
        commit();
      }
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
      sql.append("        ,program           => 'XXCSO017A03C'");
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
      if ( getTransaction().isDirty() )
      {
        // �≮������p���ς̑��݃`�F�b�N���s��
        validateReference();
    
        // ��ʍ��ڂ̓��̓`�F�b�N
        validateFixed();

        // �ۑ����������s���܂��B
        commit();
      }
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
        // ����:�]�ƈ��ԍ��i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�]�ƈ������i�����p�j
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
        // ����:���Ϗ��J�n���i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���Ϗ��I�����i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϒ�o�於�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�X�[���i�ŋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�������i�ŋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�P���ŋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�X�e�[�^�X�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���L�����i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i�R�[�h�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���i���́i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:���ϋ敪�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�X�[���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:�ʏ�X�������i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����X�[���i�i�����p�j
        sbFileData
          = createCsvStatement(sbFileData, rs.getString(rsIdx++), false);
        // ����:����X�������i�����p�j
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
   * �����≮�p���͉�ʂփ{�^������������
   * @return HashMap URL�p�����[�^
   *****************************************************************************
   */
  public HashMap handleStoreButton()
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

    // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(headerRow.getStatus()) )
    {
      // �ڋq�^�C�v�`�F�b�N
      validateAccount();

      if ( getTransaction().isDirty() )
      {
        // �≮������p���ς̑��݃`�F�b�N���s��
        validateReference();

        // ��ʍ��ڂ̓��̓`�F�b�N
        validateFixed();

        // �ۑ����������s���܂��B
        commit();
      }
    }
    else
    {
      rollback();
    }
    
    HashMap params = new HashMap();

   // ���σw�b�_�[ID
   params.put(
     XxcsoConstants.TRANSACTION_KEY1,
     ""
   );

   // �Q�Ɨp���σw�b�_�[ID
   params.put(
     XxcsoConstants.TRANSACTION_KEY2,
     headerRow.getQuoteHeaderId()
   );

    // �߂���ʖ���
    params.put(
      XxcsoConstants.TRANSACTION_KEY3,
     ""
    );

    // ���s�敪
    params.put(
      XxcsoConstants.EXECUTE_MODE,
      XxcsoQuoteConstants.TRANDIV_FROM_SALES
    );

    XxcsoUtils.debug(txn, "[END]");

    return params; 

  }

  /*****************************************************************************
   * �s�ǉ��{�^�������������i���ϖ��ו\�j
   *****************************************************************************
   */
  public void handleAddLineButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �≮������p���ς̑��݃`�F�b�N���s��
    validateReference();

    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    int maxSize
      = Integer.parseInt(txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE));
      
    if ( lineVo.getRowCount() == maxSize )
    {
      throw
        XxcsoMessage.createMaxRowException(
          XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_LINE_INFO
         ,String.valueOf(maxSize)
        );
    }
    
    // �V�K���׍s�쐬
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.createRow();

    // �������pVO�s���擾
    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();
    
    // �����l�̐ݒ�
    Date currentDate = new Date(initRow.getCurrentDate());
    lineRow.setQuoteDiv(XxcsoQuoteConstants.QUOTE_DIV_USUALLY);
    lineRow.setQuoteStartDate(initRow.getCurrentDate());
    lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));

    // �s�̍Ō�ɒǉ�
    lineVo.last();
    lineVo.next();
    lineVo.insertRow(lineRow);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �s�폜�{�^�������������i���ϖ��ו\�j
   *****************************************************************************
   */
  public void handleDelLineButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    // �C���X�^���X�擾
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    boolean existFlag = false;
    
    // �폜�Ώۖ��ׂ��`�F�b�N
    while ( lineRow != null )
    {
      if ( "Y".equals(lineRow.getSelectFlag()) )
      {
        existFlag = true;

        // �≮�����挩�ς̑��݃`�F�b�N���s��
        validateReference();
      }
      
      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    if ( ! existFlag )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00464);
    }
    
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // �����≮���Ŏg�p���Ă��Ȃ��ꍇ�͍폜���܂��B
    lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( "Y".equals(lineRow.getSelectFlag()) )
      {
        // �I������Ă��閾�׍s���폜���܂��B
        lineVo.removeCurrentRow();
      }

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * �ʏ�X�[���i���o�{�^�������������i���ϖ��ו\�j
   *****************************************************************************
   */
  public void handleRegularPriceButton()
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

    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    XxcsoUsuallyDelivPriceVOImpl usuallyVo = getXxcsoUsuallyDelivPriceVO1();

    if ( usuallyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoUsuallyDelivPriceVO1");
    }

   // ���σw�b�_�[
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

   // ���ϖ���
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
       // ���ϋ敪���ʏ�ȊO�̏ꍇ�A�ʏ�X�[���i���������o���܂��B
      if ( ! XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
             lineRow.getQuoteDiv()) )
      {
        if ( "Y".equals(lineRow.getSelectFlag()) )
        {
          // �≮������p���ς̑��݃`�F�b�N���s��
          validateReference();

          // �������s
          usuallyVo.initQuery(
            headerRow.getAccountNumber(),
            lineRow.getInventoryItemId()
          );

          // �ʏ�X�[���i�擾
          XxcsoUsuallyDelivPriceVORowImpl usuallyRow
            = (XxcsoUsuallyDelivPriceVORowImpl)usuallyVo.first();

          //�ʏ�X�[���i���擾�ł����ꍇ
          if ( usuallyRow != null )
          {
            // �擾�����ʏ�X�[���i��ݒ�
            lineRow.setUsuallyDelivPrice(usuallyRow.getUsuallyDelivPrice());
          }
        }
      }
      
      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

    // �J�[�\����擪�ɂ���
    lineVo.first();
    
    XxcsoUtils.debug(txn, "[END]");

  }

  /*****************************************************************************
   * ���ϋ敪���ύX���ꂽ����ԁi�I���j���ύX���鏈��
   * @param quoteLineId ���ϖ���ID
   *****************************************************************************
   */
  public void handleDivChange(
    String quoteLineId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // �≮������p���ς̑��݃`�F�b�N���s��
    validateReference();
    
    ////////////////
    //�C���X�^���X�擾
    ////////////////
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    // XxcsoQuoteSalesInitVO1�C���X�^���X�̎擾
    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    // ���ϖ���
    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    while ( lineRow != null )
    {
      if ( quoteLineId.equals(lineRow.getQuoteLineId().stringValue()) )
      {
        // �V�X�e�����t�擾
        XxcsoQuoteSalesInitVORowImpl initRow
          = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

        if ( lineRow.getQuoteStartDate() != null )
        {
          Date currentDate = new Date(lineRow.getQuoteStartDate());

          // ���ϋ敪���u1�v�̏ꍇ�́A1�N��B����ȊO��3������
          if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(
                 lineRow.getQuoteDiv())
             )
          {
            lineRow.setQuoteEndDate((Date)currentDate.addMonths(12));
          }
          else
          {
            lineRow.setQuoteEndDate((Date)currentDate.addMonths(3));
          }
        }
        break;
      }

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

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
    
    XxcsoQuoteLinesSalesFullVOImpl lineVo = getXxcsoQuoteLinesSalesFullVO1();
    if ( lineVo == null )
    {
      throw 
        XxcsoMessage.createInstanceLostError("XxcsoQuoteLinesSalesFullVO1");
    }

    errorList = validateHeader(errorList);

    XxcsoQuoteLinesSalesFullVORowImpl lineRow
      = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.first();

    int index = 0;
    while ( lineRow != null )
    {
      index++;
      validateLine(
        errorList
       ,lineRow
       ,index
      );

      validateFixedLine(
        errorList
       ,lineRow
       ,index
      );

      lineRow = (XxcsoQuoteLinesSalesFullVORowImpl)lineVo.next();
    }

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
   * �≮������p���ς̑��݃`�F�b�N����
   *****************************************************************************
   */
  private void validateReference()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoReferenceQuoteVOImpl refVo = getXxcsoReferenceQuoteVO1();
    if ( refVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoReferenceQuoteVO1");
    }

    List errorList = new ArrayList();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // �≮������p���ς����݂��Ă��邩���m�F
    refVo.initQuery(headerRow.getQuoteHeaderId());

    XxcsoReferenceQuoteVORowImpl refRow
      = (XxcsoReferenceQuoteVORowImpl)refVo.first();

    while ( refRow != null )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00223
           ,XxcsoConstants.TOKEN_PARAM9
           ,refRow.getQuoteNumber()
          );

      errorList.add(error);

      refRow = (XxcsoReferenceQuoteVORowImpl)refVo.next();

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
   ,XxcsoQuoteLinesSalesFullVORowImpl lineRow
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
    if ( lineRow.getUsuallyDelivPrice() == null )
    {
      lineRow.setUsuallyDelivPrice(XxcsoQuoteConstants.DEF_PRICE);
    }

    if ( lineRow.getUsuallyStoreSalePrice() == null )
    {
      lineRow.setUsuallyStoreSalePrice(XxcsoQuoteConstants.DEF_PRICE);
    }

    if ( lineRow.getThisTimeDelivPrice() == null )
    {
      lineRow.setThisTimeDelivPrice(XxcsoQuoteConstants.DEF_PRICE);
    }

    if ( lineRow.getThisTimeStoreSalePrice() == null )
    {
      lineRow.setThisTimeStoreSalePrice(XxcsoQuoteConstants.DEF_PRICE);
    }

    // ���i�R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getInventoryItemId()
         ,XxcsoQuoteConstants.TOKEN_VALUE_INVENTORY_ITEM_ID
         ,index
        );

    // �ʏ�X�[���i
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallyDelivPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_DELIV_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // �ʏ�X������
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getUsuallyStoreSalePrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_USUALLY_STORE_SALE_PRICE
         ,2
         ,6
         ,true
         ,false
         ,false
         ,index
        );

    // ����X�[���i
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeDelivPrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_DELIV_PRICE
         ,2
         ,5
         ,true
         ,false
         ,false
         ,index
        );

    // ����X������
    errorList
      = util.checkStringToNumber(
          errorList
         ,lineRow.getThisTimeStoreSalePrice()
         ,XxcsoQuoteConstants.TOKEN_VALUE_THIS_TIME_STORE_SALE_PRICE
         ,2
         ,6
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
   * @param errorList     �G���[���X�g
   * @param lineRow       ���ϖ��׍s�C���X�^���X
   * @param index         �Ώۍs
   *****************************************************************************
   */
  private List validateFixedLine(
    List                              errorList
   ,XxcsoQuoteLinesSalesFullVORowImpl lineRow
   ,int                               index
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");      
    }

    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    // �K�{�`�F�b�N���s���܂��B
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // ���i�R�[�h
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getInventoryItemId()
         ,XxcsoQuoteConstants.TOKEN_VALUE_INVENTORY_ITEM_ID
         ,index
        );

    // ���ԁi�J�n�j
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteStartDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_START_DATE
         ,index
        );

    // ���ԁi�I���j
    errorList
      = util.requiredCheck(
          errorList
         ,lineRow.getQuoteEndDate()
         ,XxcsoQuoteConstants.TOKEN_VALUE_QUOTE_END_DATE
         ,index
        );
    
    // ���ԃ`�F�b�N
    if ( lineRow.getQuoteStartDate() != null &&
         lineRow.getQuoteEndDate()   != null
       )
    {
      Date currentDate = new Date(initRow.getCurrentDate());
      Date currentDate2 = new Date(lineRow.getQuoteStartDate());
      Date limitDate = (Date)currentDate.addJulianDays(-30, 0);

      // �V�X�e�����t���30���O�܂œ��͉\
      if ( lineRow.getQuoteStartDate().compareTo(limitDate) < 0 )
      {
        XxcsoUtils.debug(txn, limitDate);

        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00463
             ,XxcsoConstants.TOKEN_INDEX
             ,String.valueOf(index)
            );
        errorList.add(error);
      }

      // ���ϋ敪���ʏ�̏ꍇ
      if( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) )
      {
        // ���ԁi�J�n�j���P�N�ȓ�
        limitDate = (Date)currentDate2.addMonths(12);

        if ( lineRow.getQuoteEndDate().compareTo(limitDate) > 0 ||
             lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
        {
          XxcsoUtils.debug(txn, limitDate);

          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00462,
                XxcsoConstants.TOKEN_VALUES,
                XxcsoQuoteConstants.TOKEN_VALUE_USUALLY,
                XxcsoConstants.TOKEN_PERIOD,
                XxcsoQuoteConstants.TOKEN_VALUE_ONE_YEAR,
                XxcsoConstants.TOKEN_INDEX,
                String.valueOf(index)
              );
          errorList.add(error);
        }
      }
      else
      {
        // ���ԁi�J�n�j���3�����ȓ�
        limitDate = (Date)currentDate2.addMonths(3);

        if ( lineRow.getQuoteEndDate().compareTo(limitDate) > 0 ||
             lineRow.getQuoteEndDate().compareTo(
                                         lineRow.getQuoteStartDate()) < 0
           )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00462,
                XxcsoConstants.TOKEN_VALUES,
                XxcsoQuoteConstants.TOKEN_VALUE_EXCULDING_USUALLY,
                XxcsoConstants.TOKEN_PERIOD,
                XxcsoQuoteConstants.TOKEN_VALUE_THREE_MONTHS,
                XxcsoConstants.TOKEN_INDEX,
                String.valueOf(index)
              );
          errorList.add(error);
        }
      }
    }
    
    if ( XxcsoQuoteConstants.QUOTE_DIV_USUALLY.equals(lineRow.getQuoteDiv()) ||
         XxcsoQuoteConstants.QUOTE_DIV_BARGAIN.equals(lineRow.getQuoteDiv())
       )
    {
      // �ʏ킩�����̏ꍇ�́A�X�[���i�̌�������`�F�b�N
      String usuallyDelivPriceRep 
        = lineRow.getUsuallyDelivPrice().replaceAll(",", "");
      String thisTimeDelivPriceRep 
        = lineRow.getThisTimeDelivPrice().replaceAll(",", "");

      double businessPrice      = lineRow.getBusinessPrice().doubleValue();

      try
      {
        double usuallyDelivPrice  = Double.parseDouble(usuallyDelivPriceRep);

        // �ʏ�X�[���i
        if ( usuallyDelivPrice <= businessPrice )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00461,
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

      try
      {
        double thisTimeDelivPrice = Double.parseDouble(thisTimeDelivPriceRep);

        // ����X�[���i
        if ( thisTimeDelivPrice <= businessPrice )
        {
          OAException error
            = XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00461,
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
    }

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
   * �ڋq�`�F�b�N����
   *****************************************************************************
   */
  private void validateAccount()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoQuoteHeadersFullVOImpl headerVo = getXxcsoQuoteHeadersFullVO1();
    if ( headerVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteHeadersFullVO1");
    }

    XxcsoAccountTypeVOImpl accountVo = getXxcsoAccountTypeVO1();
    if ( accountVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoAccountTypeVO1");
    }

    List errorList = new ArrayList();
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    // �ڋq�R�[�h�����݂��Ă��邩���m�F
    accountVo.initQuery(headerRow.getAccountNumber());

    XxcsoAccountTypeVORowImpl accountRow
      = (XxcsoAccountTypeVORowImpl)accountVo.first();

    if ( accountRow == null )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00115
          );

      errorList.add(error);
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");

  }

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

    XxcsoQuoteSalesInitVOImpl initVo = getXxcsoQuoteSalesInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoQuoteSalesInitVO1");
    }
    
    XxcsoQuoteHeadersFullVORowImpl headerRow
      = (XxcsoQuoteHeadersFullVORowImpl)headerVo.first();

    XxcsoQuoteSalesInitVORowImpl initRow
      = (XxcsoQuoteSalesInitVORowImpl)initVo.first();

    initRow.setCopyCreateButtonRender(Boolean.FALSE);
    initRow.setInvalidityButtonRender(Boolean.FALSE);
    initRow.setApplicableButtonRender(Boolean.FALSE);
    initRow.setRevisionButtonRender(Boolean.FALSE);
    initRow.setFixedButtonRender(Boolean.FALSE);
    initRow.setQuoteSheetPrintButtonRender(Boolean.FALSE);
    initRow.setCsvCreateButtonRender(Boolean.FALSE);
    initRow.setInputTranceButtonRender(Boolean.FALSE);

    String status = headerRow.getStatus();
    if ( status == null || "".equals(status.trim()) )
    {
      initRow.setApplicableButtonRender(Boolean.TRUE);
    }
    else
    {
      if ( XxcsoQuoteConstants.QUOTE_INPUT.equals(status) )
      {
        initRow.setCopyCreateButtonRender(Boolean.TRUE);
        initRow.setApplicableButtonRender(Boolean.TRUE);
        initRow.setRevisionButtonRender(Boolean.TRUE);
        initRow.setFixedButtonRender(Boolean.TRUE);
        initRow.setQuoteSheetPrintButtonRender(Boolean.TRUE);
        initRow.setCsvCreateButtonRender(Boolean.TRUE);
        initRow.setInputTranceButtonRender(Boolean.TRUE);
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
        initRow.setInputTranceButtonRender(Boolean.TRUE);
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
   * Container's getter for XxcsoStorePriceTaxTypeLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoStorePriceTaxTypeLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStorePriceTaxTypeLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoUsuallyDelivPriceVO1
   */
  public XxcsoUsuallyDelivPriceVOImpl getXxcsoUsuallyDelivPriceVO1()
  {
    return (XxcsoUsuallyDelivPriceVOImpl)findViewObject("XxcsoUsuallyDelivPriceVO1");
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
   * Container's getter for XxcsoUnitPriceDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoUnitPriceDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoUnitPriceDivLookupVO");
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
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso017001j.server", "XxcsoQuoteSalesRegistAMLocal");
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
   * Container's getter for XxcsoQuoteLinesSalesFullVO1
   */
  public XxcsoQuoteLinesSalesFullVOImpl getXxcsoQuoteLinesSalesFullVO1()
  {
    return (XxcsoQuoteLinesSalesFullVOImpl)findViewObject("XxcsoQuoteLinesSalesFullVO1");
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
   * Container's getter for XxcsoQuoteLinesSalesFullVO2
   */
  public XxcsoQuoteLinesSalesFullVOImpl getXxcsoQuoteLinesSalesFullVO2()
  {
    return (XxcsoQuoteLinesSalesFullVOImpl)findViewObject("XxcsoQuoteLinesSalesFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineSalesVL1
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineSalesVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineSalesVL1");
  }

  /**
   * 
   * Container's getter for XxcsoQuoteHeaderLineSalesVL2
   */
  public ViewLinkImpl getXxcsoQuoteHeaderLineSalesVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoQuoteHeaderLineSalesVL2");
  }



  /**
   * 
   * Container's getter for XxcsoReferenceQuoteVO1
   */
  public XxcsoReferenceQuoteVOImpl getXxcsoReferenceQuoteVO1()
  {
    return (XxcsoReferenceQuoteVOImpl)findViewObject("XxcsoReferenceQuoteVO1");
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
   * Container's getter for XxcsoQuoteSalesInitVO1
   */
  public XxcsoQuoteSalesInitVOImpl getXxcsoQuoteSalesInitVO1()
  {
    return (XxcsoQuoteSalesInitVOImpl)findViewObject("XxcsoQuoteSalesInitVO1");
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
   * Container's getter for XxcsoCsvQueryVO1
   */
  public XxcsoCsvQueryVOImpl getXxcsoCsvQueryVO1()
  {
    return (XxcsoCsvQueryVOImpl)findViewObject("XxcsoCsvQueryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAccountTypeVO1
   */
  public XxcsoAccountTypeVOImpl getXxcsoAccountTypeVO1()
  {
    return (XxcsoAccountTypeVOImpl)findViewObject("XxcsoAccountTypeVO1");
  }







}