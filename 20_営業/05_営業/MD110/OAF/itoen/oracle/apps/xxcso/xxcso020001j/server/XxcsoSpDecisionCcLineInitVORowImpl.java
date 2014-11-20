/*============================================================================
* �t�@�C���� : XxcsoSpDecisionCcLineInitVORowImpl
* �T�v����   : �ꗥ�����E�e��ʏ����������p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * �ꗥ�����E�e��ʏ��������������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionCcLineInitVORowImpl extends OAViewRowImpl 
{


  protected static final int SPCONTAINERTYPE = 0;
  protected static final int DEFINEDFIXEDPRICE = 1;
  protected static final int DEFINEDCOSTRATE = 2;
  protected static final int COSTPRICE = 3;
  protected static final int SORTCODE = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionCcLineInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SpContainerType
   */
  public String getSpContainerType()
  {
    return (String)getAttributeInternal(SPCONTAINERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SpContainerType
   */
  public void setSpContainerType(String value)
  {
    setAttributeInternal(SPCONTAINERTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DefinedFixedPrice
   */
  public Number getDefinedFixedPrice()
  {
    return (Number)getAttributeInternal(DEFINEDFIXEDPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DefinedFixedPrice
   */
  public void setDefinedFixedPrice(Number value)
  {
    setAttributeInternal(DEFINEDFIXEDPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute DefinedCostRate
   */
  public Number getDefinedCostRate()
  {
    return (Number)getAttributeInternal(DEFINEDCOSTRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DefinedCostRate
   */
  public void setDefinedCostRate(Number value)
  {
    setAttributeInternal(DEFINEDCOSTRATE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute CostPrice
   */
  public Number getCostPrice()
  {
    return (Number)getAttributeInternal(COSTPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute CostPrice
   */
  public void setCostPrice(Number value)
  {
    setAttributeInternal(COSTPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SortCode
   */
  public String getSortCode()
  {
    return (String)getAttributeInternal(SORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SortCode
   */
  public void setSortCode(String value)
  {
    setAttributeInternal(SORTCODE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPCONTAINERTYPE:
        return getSpContainerType();
      case DEFINEDFIXEDPRICE:
        return getDefinedFixedPrice();
      case DEFINEDCOSTRATE:
        return getDefinedCostRate();
      case COSTPRICE:
        return getCostPrice();
      case SORTCODE:
        return getSortCode();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPCONTAINERTYPE:
        setSpContainerType((String)value);
        return;
      case DEFINEDFIXEDPRICE:
        setDefinedFixedPrice((Number)value);
        return;
      case DEFINEDCOSTRATE:
        setDefinedCostRate((Number)value);
        return;
      case COSTPRICE:
        setCostPrice((Number)value);
        return;
      case SORTCODE:
        setSortCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}