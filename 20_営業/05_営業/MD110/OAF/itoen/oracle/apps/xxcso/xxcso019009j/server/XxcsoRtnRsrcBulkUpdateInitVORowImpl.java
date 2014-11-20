/*============================================================================
* �t�@�C���� : XxcsoRtnRsrcBulkUpdateInitVORowImpl
* �T�v����   : ��ʕێ����p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS�x���a��    �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * ��ʕێ����̃r���[�s�N���X�ł��B
 * @author  SCS�x���a��
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateInitVORowImpl extends OAViewRowImpl 
{


  protected static final int CURRENTDATE = 0;
  protected static final int BASECODE = 1;
  protected static final int EMPLOYEENUMBER = 2;
  protected static final int FULLNAME = 3;
  protected static final int ROUTENO = 4;
  protected static final int REFLECTMETHOD = 5;
  protected static final int ADDCUSTOMERBUTTONRENDER = 6;
  protected static final int FIRSTDATE = 7;
  protected static final int NEXTDATE = 8;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CurrentDate
   */
  public Date getCurrentDate()
  {
    return (Date)getAttributeInternal(CURRENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CurrentDate
   */
  public void setCurrentDate(Date value)
  {
    setAttributeInternal(CURRENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CURRENTDATE:
        return getCurrentDate();
      case BASECODE:
        return getBaseCode();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case ROUTENO:
        return getRouteNo();
      case REFLECTMETHOD:
        return getReflectMethod();
      case ADDCUSTOMERBUTTONRENDER:
        return getAddCustomerButtonRender();
      case FIRSTDATE:
        return getFirstDate();
      case NEXTDATE:
        return getNextDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CURRENTDATE:
        setCurrentDate((Date)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case ROUTENO:
        setRouteNo((String)value);
        return;
      case REFLECTMETHOD:
        setReflectMethod((String)value);
        return;
      case ADDCUSTOMERBUTTONRENDER:
        setAddCustomerButtonRender((Boolean)value);
        return;
      case FIRSTDATE:
        setFirstDate((Date)value);
        return;
      case NEXTDATE:
        setNextDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RouteNo
   */
  public String getRouteNo()
  {
    return (String)getAttributeInternal(ROUTENO);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RouteNo
   */
  public void setRouteNo(String value)
  {
    setAttributeInternal(ROUTENO, value);
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute AddCustomerButtonRender
   */
  public Boolean getAddCustomerButtonRender()
  {
    return (Boolean)getAttributeInternal(ADDCUSTOMERBUTTONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AddCustomerButtonRender
   */
  public void setAddCustomerButtonRender(Boolean value)
  {
    setAttributeInternal(ADDCUSTOMERBUTTONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReflectMethod
   */
  public String getReflectMethod()
  {
    return (String)getAttributeInternal(REFLECTMETHOD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReflectMethod
   */
  public void setReflectMethod(String value)
  {
    setAttributeInternal(REFLECTMETHOD, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NextDate
   */
  public Date getNextDate()
  {
    return (Date)getAttributeInternal(NEXTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NextDate
   */
  public void setNextDate(Date value)
  {
    setAttributeInternal(NEXTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FirstDate
   */
  public Date getFirstDate()
  {
    return (Date)getAttributeInternal(FIRSTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FirstDate
   */
  public void setFirstDate(Date value)
  {
    setAttributeInternal(FIRSTDATE, value);
  }













}