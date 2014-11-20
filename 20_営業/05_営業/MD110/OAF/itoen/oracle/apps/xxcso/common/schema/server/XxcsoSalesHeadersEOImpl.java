/*============================================================================
* �t�@�C���� : XxcsoSalesHeadersEOImpl
* �T�v����   : ���k������w�b�_�G���e�B�e�B�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.RowIterator;
import oracle.jbo.AttributeList;
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;
import oracle.jbo.DMLException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import com.sun.java.util.collections.Iterator;
import java.sql.SQLException;

/*******************************************************************************
 * ���k������w�b�_�̃G���e�B�e�B�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesHeadersEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SALESHEADERID = 0;
  protected static final int LEADID = 1;
  protected static final int OTHERCONTENT = 2;
  protected static final int CREATEDBY = 3;
  protected static final int CREATIONDATE = 4;
  protected static final int LASTUPDATEDBY = 5;
  protected static final int LASTUPDATEDATE = 6;
  protected static final int LASTUPDATELOGIN = 7;
  protected static final int REQUESTID = 8;
  protected static final int PROGRAMAPPLICATIONID = 9;
  protected static final int PROGRAMID = 10;
  protected static final int PROGRAMUPDATEDATE = 11;
  protected static final int XXCSOSALESLINESVEO = 12;









































  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesHeadersEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesHeadersEO");
    }
    return mDefinitionObject;
  }







































  /*****************************************************************************
   * �G���e�B�e�B�G�L�X�p�[�g�C���X�^���X�̎擾�����ł��B
   * @param txn OADBTransaction�C���X�^���X
   *****************************************************************************
   */
  public static XxcsoCommonEntityExpert getXxcsoCommonEntityExpert(
    OADBTransaction txn
  )
  {
    return
      (XxcsoCommonEntityExpert)
        txn.getExpert(XxcsoSalesHeadersEOImpl.getDefinitionObject());
  }

  /*****************************************************************************
   * �G���e�B�e�B�̍쐬�����ł��B
   * @param list �������X�g
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    // ���̒l��ݒ肵�܂��B
    setSalesHeaderId(new Number(-1));

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * ���R�[�h���b�N�����ł��B
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    String leadNumber = expert.getLeadNumber(getLeadId());
    
    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
      );      
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ���R�[�h�쐬�����ł��B
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    String leadNumber = expert.getLeadNumber(getLeadId());
    
    // �o�^���钼�O�ŃV�[�P���X�l�𕥂��o���܂��B
    Number salesHeaderId
      = getOADBTransaction().getSequenceValue("XXCSO_SALES_HEADERS_S01");

    setSalesHeaderId(salesHeaderId);

    try
    {
      // ���k������͂P�̏��k�ɑ΂��ĂP�̂��߁A
      // UNIQUE KEY�G���[����������
      super.insertRow();
    }
    catch ( DMLException e )
    {
      Object[] exceptions = e.getDetails();
      if ( exceptions != null && exceptions.length > 0 )
      {
        if ( exceptions[0] instanceof SQLException )
        {
          SQLException exception = (SQLException)exceptions[0];
          int code = exception.getErrorCode();
          if ( code == 1 )
          {
            throw XxcsoMessage.createTransactionInconsistentError(
                    XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
                      + leadNumber
                  );
          }
        }
      }

      XxcsoUtils.unexpected(txn, e);

      throw e;
    }

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * ���R�[�h�X�V�����ł��B
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    super.updateRow();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * ���R�[�h�폜�����ł��B
   * �Ă΂�Ȃ��͂��Ȃ̂ŋ�U�肵�܂��B
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }



  /*****************************************************************************
   * ���R�[�h�ύX�m�F�����ł��B
   *****************************************************************************
   */
  public static boolean isModified(OADBTransaction txn)
  {
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoSalesHeadersEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    boolean modified = false;

    while ( it.hasNext() )
    {
      XxcsoSalesHeadersEOImpl eo = (XxcsoSalesHeadersEOImpl)it.next();
      if ( eo.getEntityState() != STATUS_UNMODIFIED &&
           eo.getEntityState() != STATUS_INITIALIZED
         )
      {
        XxcsoUtils.debug(
          txn
         ,"headerEo modified" +
            " id:" + eo.getSalesHeaderId() +
            " status:" + eo.getEntityState()
        );
        modified = true;
        break;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return modified;
  }



  /**
   * 
   * Gets the attribute value for SalesHeaderId, using the alias name SalesHeaderId
   */
  public Number getSalesHeaderId()
  {
    return (Number)getAttributeInternal(SALESHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesHeaderId
   */
  public void setSalesHeaderId(Number value)
  {
    setAttributeInternal(SALESHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for LeadId, using the alias name LeadId
   */
  public Number getLeadId()
  {
    return (Number)getAttributeInternal(LEADID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LeadId
   */
  public void setLeadId(Number value)
  {
    setAttributeInternal(LEADID, value);
  }

  /**
   * 
   * Gets the attribute value for OtherContent, using the alias name OtherContent
   */
  public String getOtherContent()
  {
    return (String)getAttributeInternal(OTHERCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OtherContent
   */
  public void setOtherContent(String value)
  {
    setAttributeInternal(OTHERCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESHEADERID:
        return getSalesHeaderId();
      case LEADID:
        return getLeadId();
      case OTHERCONTENT:
        return getOtherContent();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case XXCSOSALESLINESVEO:
        return getXxcsoSalesLinesVEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESHEADERID:
        setSalesHeaderId((Number)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSalesLinesVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSALESLINESVEO);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number salesHeaderId)
  {
    return new Key(new Object[] {salesHeaderId});
  }
















































}