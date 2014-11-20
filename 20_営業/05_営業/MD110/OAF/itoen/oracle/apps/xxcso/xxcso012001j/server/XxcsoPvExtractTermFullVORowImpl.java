/*============================================================================
* ファイル名 : XxcsoPvExtractTermFullVORowImpl
* 概要説明   : パーソナライズビュー作成画面／汎用検索抽出条件定義取得ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * 汎用検索抽出条件定義取得ビュー行クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractTermFullVORowImpl extends OAViewRowImpl 
{


  protected static final int EXTRACTTERMDEFID = 0;
  protected static final int VIEWID = 1;
  protected static final int SETUPNUMBER = 2;
  protected static final int COLUMNCODE = 3;
  protected static final int EXTRACTMETHODCODE = 4;
  protected static final int EXTRACTTERMTEXT = 5;
  protected static final int EXTRACTTERMNUMBER = 6;
  protected static final int EXTRACTTERMDATE = 7;
  protected static final int CREATEDBY = 8;
  protected static final int CREATIONDATE = 9;
  protected static final int LASTUPDATEDBY = 10;
  protected static final int LASTUPDATEDATE = 11;
  protected static final int LASTUPDATELOGIN = 12;
  protected static final int REQUESTID = 13;
  protected static final int PROGRAMAPPLICATIONID = 14;
  protected static final int PROGRAMID = 15;
  protected static final int PROGRAMUPDATEDATE = 16;
  protected static final int LOOKUPCODE = 17;
  protected static final int DESCRIPTION = 18;
  protected static final int SELECTFLAG = 19;
  protected static final int EXTRACTRENDER010 = 20;
  protected static final int EXTRACTRENDER020 = 21;
  protected static final int EXTRACTRENDER030 = 22;
  protected static final int EXTRACTRENDER040 = 23;
  protected static final int EXTRACTRENDER050 = 24;
  protected static final int EXTRACTRENDER060 = 25;
  protected static final int EXTRACTRENDER070 = 26;
  protected static final int EXTRACTRENDER080 = 27;
  protected static final int EXTRACTRENDER090 = 28;
  protected static final int EXTRACTRENDER100 = 29;
  protected static final int EXTRACTRENDER110 = 30;
  protected static final int EXTRACTRENDER120 = 31;
  protected static final int EXTRACTRENDER130 = 32;
  protected static final int EXTRACTRENDER140 = 33;
  protected static final int EXTRACTRENDER150 = 34;
  protected static final int EXTRACTRENDER160 = 35;
  protected static final int EXTRACTRENDER170 = 36;
  protected static final int EXTRACTRENDER180 = 37;
  protected static final int EXTRACTRENDER190 = 38;
  protected static final int EXTRACTRENDER200 = 39;
  protected static final int EXTRACTRENDER210 = 40;
  protected static final int EXTRACTRENDER220 = 41;
  protected static final int EXTRACTRENDER230 = 42;
  protected static final int EXTRACTRENDER240 = 43;
  protected static final int EXTRACTRENDER250 = 44;
  protected static final int EXTRACTRENDER260 = 45;
  protected static final int EXTRACTRENDER270 = 46;
  protected static final int EXTRACTRENDER280 = 47;
  protected static final int EXTRACTRENDER290 = 48;
  protected static final int EXTRACTRENDER300 = 49;
  protected static final int EXTRACTRENDER310 = 50;
  protected static final int EXTRACTRENDER320 = 51;
  protected static final int EXTRACTRENDER330 = 52;
  protected static final int EXTRACTRENDER340 = 53;
  protected static final int EXTRACTRENDER350 = 54;
  protected static final int EXTRACTRENDER360 = 55;
  protected static final int EXTRACTRENDER370 = 56;
  protected static final int EXTRACTRENDER380 = 57;
  protected static final int EXTRACTRENDER390 = 58;
  protected static final int EXTRACTRENDER400 = 59;
  protected static final int EXTRACTRENDER410 = 60;
  protected static final int EXTRACTRENDER420 = 61;
  protected static final int EXTRACTRENDER430 = 62;
  protected static final int EXTRACTRENDER440 = 63;
  protected static final int EXTRACTRENDER450 = 64;
  protected static final int EXTRACTRENDER460 = 65;
  protected static final int EXTRACTRENDER470 = 66;
  protected static final int EXTRACTRENDER480 = 67;
  protected static final int EXTRACTRENDER490 = 68;
  protected static final int EXTRACTRENDER500 = 69;
  protected static final int EXTRACTRENDER510 = 70;
  protected static final int EXTRACTRENDER520 = 71;
  protected static final int EXTRACTRENDER530 = 72;
  protected static final int EXTRACTRENDER540 = 73;
  protected static final int EXTRACTRENDER550 = 74;
  protected static final int EXTRACTRENDER560 = 75;
  protected static final int EXTRACTRENDER570 = 76;
  protected static final int EXTRACTRENDER580 = 77;
  protected static final int EXTRACTRENDER590 = 78;
  protected static final int EXTRACTRENDER600 = 79;
  protected static final int EXTRACTRENDER610 = 80;
  protected static final int EXTRACTRENDER620 = 81;
  protected static final int EXTRACTRENDER630 = 82;
  protected static final int EXTRACTRENDER640 = 83;
  protected static final int EXTRACTRENDER650 = 84;
  protected static final int EXTRACTRENDER660 = 85;
  protected static final int EXTRACTRENDER670 = 86;
  protected static final int EXTRACTRENDER680 = 87;
  protected static final int EXTRACTRENDER690 = 88;
  protected static final int EXTRACTRENDER700 = 89;
  protected static final int EXTRACTRENDER710 = 90;
  protected static final int EXTRACTRENDER720 = 91;
  protected static final int EXTRACTRENDER730 = 92;
  protected static final int EXTRACTRENDER740 = 93;
  protected static final int EXTRACTRENDER750 = 94;
  protected static final int EXTRACTRENDER760 = 95;
  protected static final int EXTRACTRENDER770 = 96;
  protected static final int EXTRACTRENDER780 = 97;
  protected static final int EXTRACTRENDER790 = 98;
  protected static final int EXTRACTRENDER800 = 99;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractTermFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoPvExtractTermDefVEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvExtractTermDefVEOImpl getXxcsoPvExtractTermDefVEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvExtractTermDefVEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_TERM_DEF_ID using the alias name ExtractTermDefId
   */
  public Number getExtractTermDefId()
  {
    return (Number)getAttributeInternal(EXTRACTTERMDEFID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_TERM_DEF_ID using the alias name ExtractTermDefId
   */
  public void setExtractTermDefId(Number value)
  {
    setAttributeInternal(EXTRACTTERMDEFID, value);
  }

  /**
   * 
   * Gets the attribute value for VIEW_ID using the alias name ViewId
   */
  public Number getViewId()
  {
    return (Number)getAttributeInternal(VIEWID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VIEW_ID using the alias name ViewId
   */
  public void setViewId(Number value)
  {
    setAttributeInternal(VIEWID, value);
  }

  /**
   * 
   * Gets the attribute value for SETUP_NUMBER using the alias name SetupNumber
   */
  public Number getSetupNumber()
  {
    return (Number)getAttributeInternal(SETUPNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SETUP_NUMBER using the alias name SetupNumber
   */
  public void setSetupNumber(Number value)
  {
    setAttributeInternal(SETUPNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for COLUMN_CODE using the alias name ColumnCode
   */
  public String getColumnCode()
  {
    return (String)getAttributeInternal(COLUMNCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for COLUMN_CODE using the alias name ColumnCode
   */
  public void setColumnCode(String value)
  {
    setAttributeInternal(COLUMNCODE, value);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_METHOD_CODE using the alias name ExtractMethodCode
   */
  public String getExtractMethodCode()
  {
    return (String)getAttributeInternal(EXTRACTMETHODCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_METHOD_CODE using the alias name ExtractMethodCode
   */
  public void setExtractMethodCode(String value)
  {
    setAttributeInternal(EXTRACTMETHODCODE, value);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_TERM_TEXT using the alias name ExtractTermText
   */
  public String getExtractTermText()
  {
    return (String)getAttributeInternal(EXTRACTTERMTEXT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_TERM_TEXT using the alias name ExtractTermText
   */
  public void setExtractTermText(String value)
  {
    setAttributeInternal(EXTRACTTERMTEXT, value);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_TERM_NUMBER using the alias name ExtractTermNumber
   */
  public String getExtractTermNumber()
  {
    return (String)getAttributeInternal(EXTRACTTERMNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_TERM_NUMBER using the alias name ExtractTermNumber
   */
  public void setExtractTermNumber(String value)
  {
    setAttributeInternal(EXTRACTTERMNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_TERM_DATE using the alias name ExtractTermDate
   */
  public Date getExtractTermDate()
  {
    return (Date)getAttributeInternal(EXTRACTTERMDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_TERM_DATE using the alias name ExtractTermDate
   */
  public void setExtractTermDate(Date value)
  {
    setAttributeInternal(EXTRACTTERMDATE, value);
  }

  /**
   * 
   * Gets the attribute value for CREATED_BY using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for REQUEST_ID using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REQUEST_ID using the alias name RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
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
      case EXTRACTTERMDEFID:
        return getExtractTermDefId();
      case VIEWID:
        return getViewId();
      case SETUPNUMBER:
        return getSetupNumber();
      case COLUMNCODE:
        return getColumnCode();
      case EXTRACTMETHODCODE:
        return getExtractMethodCode();
      case EXTRACTTERMTEXT:
        return getExtractTermText();
      case EXTRACTTERMNUMBER:
        return getExtractTermNumber();
      case EXTRACTTERMDATE:
        return getExtractTermDate();
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
      case LOOKUPCODE:
        return getLookupCode();
      case DESCRIPTION:
        return getDescription();
      case SELECTFLAG:
        return getSelectFlag();
      case EXTRACTRENDER010:
        return getExtractRender010();
      case EXTRACTRENDER020:
        return getExtractRender020();
      case EXTRACTRENDER030:
        return getExtractRender030();
      case EXTRACTRENDER040:
        return getExtractRender040();
      case EXTRACTRENDER050:
        return getExtractRender050();
      case EXTRACTRENDER060:
        return getExtractRender060();
      case EXTRACTRENDER070:
        return getExtractRender070();
      case EXTRACTRENDER080:
        return getExtractRender080();
      case EXTRACTRENDER090:
        return getExtractRender090();
      case EXTRACTRENDER100:
        return getExtractRender100();
      case EXTRACTRENDER110:
        return getExtractRender110();
      case EXTRACTRENDER120:
        return getExtractRender120();
      case EXTRACTRENDER130:
        return getExtractRender130();
      case EXTRACTRENDER140:
        return getExtractRender140();
      case EXTRACTRENDER150:
        return getExtractRender150();
      case EXTRACTRENDER160:
        return getExtractRender160();
      case EXTRACTRENDER170:
        return getExtractRender170();
      case EXTRACTRENDER180:
        return getExtractRender180();
      case EXTRACTRENDER190:
        return getExtractRender190();
      case EXTRACTRENDER200:
        return getExtractRender200();
      case EXTRACTRENDER210:
        return getExtractRender210();
      case EXTRACTRENDER220:
        return getExtractRender220();
      case EXTRACTRENDER230:
        return getExtractRender230();
      case EXTRACTRENDER240:
        return getExtractRender240();
      case EXTRACTRENDER250:
        return getExtractRender250();
      case EXTRACTRENDER260:
        return getExtractRender260();
      case EXTRACTRENDER270:
        return getExtractRender270();
      case EXTRACTRENDER280:
        return getExtractRender280();
      case EXTRACTRENDER290:
        return getExtractRender290();
      case EXTRACTRENDER300:
        return getExtractRender300();
      case EXTRACTRENDER310:
        return getExtractRender310();
      case EXTRACTRENDER320:
        return getExtractRender320();
      case EXTRACTRENDER330:
        return getExtractRender330();
      case EXTRACTRENDER340:
        return getExtractRender340();
      case EXTRACTRENDER350:
        return getExtractRender350();
      case EXTRACTRENDER360:
        return getExtractRender360();
      case EXTRACTRENDER370:
        return getExtractRender370();
      case EXTRACTRENDER380:
        return getExtractRender380();
      case EXTRACTRENDER390:
        return getExtractRender390();
      case EXTRACTRENDER400:
        return getExtractRender400();
      case EXTRACTRENDER410:
        return getExtractRender410();
      case EXTRACTRENDER420:
        return getExtractRender420();
      case EXTRACTRENDER430:
        return getExtractRender430();
      case EXTRACTRENDER440:
        return getExtractRender440();
      case EXTRACTRENDER450:
        return getExtractRender450();
      case EXTRACTRENDER460:
        return getExtractRender460();
      case EXTRACTRENDER470:
        return getExtractRender470();
      case EXTRACTRENDER480:
        return getExtractRender480();
      case EXTRACTRENDER490:
        return getExtractRender490();
      case EXTRACTRENDER500:
        return getExtractRender500();
      case EXTRACTRENDER510:
        return getExtractRender510();
      case EXTRACTRENDER520:
        return getExtractRender520();
      case EXTRACTRENDER530:
        return getExtractRender530();
      case EXTRACTRENDER540:
        return getExtractRender540();
      case EXTRACTRENDER550:
        return getExtractRender550();
      case EXTRACTRENDER560:
        return getExtractRender560();
      case EXTRACTRENDER570:
        return getExtractRender570();
      case EXTRACTRENDER580:
        return getExtractRender580();
      case EXTRACTRENDER590:
        return getExtractRender590();
      case EXTRACTRENDER600:
        return getExtractRender600();
      case EXTRACTRENDER610:
        return getExtractRender610();
      case EXTRACTRENDER620:
        return getExtractRender620();
      case EXTRACTRENDER630:
        return getExtractRender630();
      case EXTRACTRENDER640:
        return getExtractRender640();
      case EXTRACTRENDER650:
        return getExtractRender650();
      case EXTRACTRENDER660:
        return getExtractRender660();
      case EXTRACTRENDER670:
        return getExtractRender670();
      case EXTRACTRENDER680:
        return getExtractRender680();
      case EXTRACTRENDER690:
        return getExtractRender690();
      case EXTRACTRENDER700:
        return getExtractRender700();
      case EXTRACTRENDER710:
        return getExtractRender710();
      case EXTRACTRENDER720:
        return getExtractRender720();
      case EXTRACTRENDER730:
        return getExtractRender730();
      case EXTRACTRENDER740:
        return getExtractRender740();
      case EXTRACTRENDER750:
        return getExtractRender750();
      case EXTRACTRENDER760:
        return getExtractRender760();
      case EXTRACTRENDER770:
        return getExtractRender770();
      case EXTRACTRENDER780:
        return getExtractRender780();
      case EXTRACTRENDER790:
        return getExtractRender790();
      case EXTRACTRENDER800:
        return getExtractRender800();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EXTRACTTERMDEFID:
        setExtractTermDefId((Number)value);
        return;
      case VIEWID:
        setViewId((Number)value);
        return;
      case SETUPNUMBER:
        setSetupNumber((Number)value);
        return;
      case COLUMNCODE:
        setColumnCode((String)value);
        return;
      case EXTRACTMETHODCODE:
        setExtractMethodCode((String)value);
        return;
      case EXTRACTTERMTEXT:
        setExtractTermText((String)value);
        return;
      case EXTRACTTERMNUMBER:
        setExtractTermNumber((String)value);
        return;
      case EXTRACTTERMDATE:
        setExtractTermDate((Date)value);
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
      case DESCRIPTION:
        setDescription((String)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case EXTRACTRENDER010:
        setExtractRender010((Boolean)value);
        return;
      case EXTRACTRENDER020:
        setExtractRender020((Boolean)value);
        return;
      case EXTRACTRENDER030:
        setExtractRender030((Boolean)value);
        return;
      case EXTRACTRENDER040:
        setExtractRender040((Boolean)value);
        return;
      case EXTRACTRENDER050:
        setExtractRender050((Boolean)value);
        return;
      case EXTRACTRENDER060:
        setExtractRender060((Boolean)value);
        return;
      case EXTRACTRENDER070:
        setExtractRender070((Boolean)value);
        return;
      case EXTRACTRENDER080:
        setExtractRender080((Boolean)value);
        return;
      case EXTRACTRENDER090:
        setExtractRender090((Boolean)value);
        return;
      case EXTRACTRENDER100:
        setExtractRender100((Boolean)value);
        return;
      case EXTRACTRENDER110:
        setExtractRender110((Boolean)value);
        return;
      case EXTRACTRENDER120:
        setExtractRender120((Boolean)value);
        return;
      case EXTRACTRENDER130:
        setExtractRender130((Boolean)value);
        return;
      case EXTRACTRENDER140:
        setExtractRender140((Boolean)value);
        return;
      case EXTRACTRENDER150:
        setExtractRender150((Boolean)value);
        return;
      case EXTRACTRENDER160:
        setExtractRender160((Boolean)value);
        return;
      case EXTRACTRENDER170:
        setExtractRender170((Boolean)value);
        return;
      case EXTRACTRENDER180:
        setExtractRender180((Boolean)value);
        return;
      case EXTRACTRENDER190:
        setExtractRender190((Boolean)value);
        return;
      case EXTRACTRENDER200:
        setExtractRender200((Boolean)value);
        return;
      case EXTRACTRENDER210:
        setExtractRender210((Boolean)value);
        return;
      case EXTRACTRENDER220:
        setExtractRender220((Boolean)value);
        return;
      case EXTRACTRENDER230:
        setExtractRender230((Boolean)value);
        return;
      case EXTRACTRENDER240:
        setExtractRender240((Boolean)value);
        return;
      case EXTRACTRENDER250:
        setExtractRender250((Boolean)value);
        return;
      case EXTRACTRENDER260:
        setExtractRender260((Boolean)value);
        return;
      case EXTRACTRENDER270:
        setExtractRender270((Boolean)value);
        return;
      case EXTRACTRENDER280:
        setExtractRender280((Boolean)value);
        return;
      case EXTRACTRENDER290:
        setExtractRender290((Boolean)value);
        return;
      case EXTRACTRENDER300:
        setExtractRender300((Boolean)value);
        return;
      case EXTRACTRENDER310:
        setExtractRender310((Boolean)value);
        return;
      case EXTRACTRENDER320:
        setExtractRender320((Boolean)value);
        return;
      case EXTRACTRENDER330:
        setExtractRender330((Boolean)value);
        return;
      case EXTRACTRENDER340:
        setExtractRender340((Boolean)value);
        return;
      case EXTRACTRENDER350:
        setExtractRender350((Boolean)value);
        return;
      case EXTRACTRENDER360:
        setExtractRender360((Boolean)value);
        return;
      case EXTRACTRENDER370:
        setExtractRender370((Boolean)value);
        return;
      case EXTRACTRENDER380:
        setExtractRender380((Boolean)value);
        return;
      case EXTRACTRENDER390:
        setExtractRender390((Boolean)value);
        return;
      case EXTRACTRENDER400:
        setExtractRender400((Boolean)value);
        return;
      case EXTRACTRENDER410:
        setExtractRender410((Boolean)value);
        return;
      case EXTRACTRENDER420:
        setExtractRender420((Boolean)value);
        return;
      case EXTRACTRENDER430:
        setExtractRender430((Boolean)value);
        return;
      case EXTRACTRENDER440:
        setExtractRender440((Boolean)value);
        return;
      case EXTRACTRENDER450:
        setExtractRender450((Boolean)value);
        return;
      case EXTRACTRENDER460:
        setExtractRender460((Boolean)value);
        return;
      case EXTRACTRENDER470:
        setExtractRender470((Boolean)value);
        return;
      case EXTRACTRENDER480:
        setExtractRender480((Boolean)value);
        return;
      case EXTRACTRENDER490:
        setExtractRender490((Boolean)value);
        return;
      case EXTRACTRENDER500:
        setExtractRender500((Boolean)value);
        return;
      case EXTRACTRENDER510:
        setExtractRender510((Boolean)value);
        return;
      case EXTRACTRENDER520:
        setExtractRender520((Boolean)value);
        return;
      case EXTRACTRENDER530:
        setExtractRender530((Boolean)value);
        return;
      case EXTRACTRENDER540:
        setExtractRender540((Boolean)value);
        return;
      case EXTRACTRENDER550:
        setExtractRender550((Boolean)value);
        return;
      case EXTRACTRENDER560:
        setExtractRender560((Boolean)value);
        return;
      case EXTRACTRENDER570:
        setExtractRender570((Boolean)value);
        return;
      case EXTRACTRENDER580:
        setExtractRender580((Boolean)value);
        return;
      case EXTRACTRENDER590:
        setExtractRender590((Boolean)value);
        return;
      case EXTRACTRENDER600:
        setExtractRender600((Boolean)value);
        return;
      case EXTRACTRENDER610:
        setExtractRender610((Boolean)value);
        return;
      case EXTRACTRENDER620:
        setExtractRender620((Boolean)value);
        return;
      case EXTRACTRENDER630:
        setExtractRender630((Boolean)value);
        return;
      case EXTRACTRENDER640:
        setExtractRender640((Boolean)value);
        return;
      case EXTRACTRENDER650:
        setExtractRender650((Boolean)value);
        return;
      case EXTRACTRENDER660:
        setExtractRender660((Boolean)value);
        return;
      case EXTRACTRENDER670:
        setExtractRender670((Boolean)value);
        return;
      case EXTRACTRENDER680:
        setExtractRender680((Boolean)value);
        return;
      case EXTRACTRENDER690:
        setExtractRender690((Boolean)value);
        return;
      case EXTRACTRENDER700:
        setExtractRender700((Boolean)value);
        return;
      case EXTRACTRENDER710:
        setExtractRender710((Boolean)value);
        return;
      case EXTRACTRENDER720:
        setExtractRender720((Boolean)value);
        return;
      case EXTRACTRENDER730:
        setExtractRender730((Boolean)value);
        return;
      case EXTRACTRENDER740:
        setExtractRender740((Boolean)value);
        return;
      case EXTRACTRENDER750:
        setExtractRender750((Boolean)value);
        return;
      case EXTRACTRENDER760:
        setExtractRender760((Boolean)value);
        return;
      case EXTRACTRENDER770:
        setExtractRender770((Boolean)value);
        return;
      case EXTRACTRENDER780:
        setExtractRender780((Boolean)value);
        return;
      case EXTRACTRENDER790:
        setExtractRender790((Boolean)value);
        return;
      case EXTRACTRENDER800:
        setExtractRender800((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }





  /**
   * 
   * Gets the attribute value for the calculated attribute LookupCode
   */
  public String getLookupCode()
  {
    return (String)getAttributeInternal(LOOKUPCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LookupCode
   */
  public void setLookupCode(String value)
  {
    setAttributeInternal(LOOKUPCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender010
   */
  public Boolean getExtractRender010()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER010);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender010
   */
  public void setExtractRender010(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER010, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender020
   */
  public Boolean getExtractRender020()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER020);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender020
   */
  public void setExtractRender020(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER020, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Description
   */
  public String getDescription()
  {
    return (String)getAttributeInternal(DESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Description
   */
  public void setDescription(String value)
  {
    setAttributeInternal(DESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender030
   */
  public Boolean getExtractRender030()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER030);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender030
   */
  public void setExtractRender030(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER030, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender040
   */
  public Boolean getExtractRender040()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER040);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender040
   */
  public void setExtractRender040(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER040, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender050
   */
  public Boolean getExtractRender050()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER050);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender050
   */
  public void setExtractRender050(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER050, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender060
   */
  public Boolean getExtractRender060()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER060);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender060
   */
  public void setExtractRender060(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER060, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender070
   */
  public Boolean getExtractRender070()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER070);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender070
   */
  public void setExtractRender070(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER070, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender080
   */
  public Boolean getExtractRender080()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER080);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender080
   */
  public void setExtractRender080(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER080, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender090
   */
  public Boolean getExtractRender090()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER090);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender090
   */
  public void setExtractRender090(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER090, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender100
   */
  public Boolean getExtractRender100()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER100);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender100
   */
  public void setExtractRender100(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER100, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender110
   */
  public Boolean getExtractRender110()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER110);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender110
   */
  public void setExtractRender110(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER110, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender120
   */
  public Boolean getExtractRender120()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER120);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender120
   */
  public void setExtractRender120(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER120, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender130
   */
  public Boolean getExtractRender130()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER130);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender130
   */
  public void setExtractRender130(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER130, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender140
   */
  public Boolean getExtractRender140()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER140);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender140
   */
  public void setExtractRender140(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER140, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender150
   */
  public Boolean getExtractRender150()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER150);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender150
   */
  public void setExtractRender150(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER150, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender160
   */
  public Boolean getExtractRender160()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER160);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender160
   */
  public void setExtractRender160(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER160, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender170
   */
  public Boolean getExtractRender170()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER170);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender170
   */
  public void setExtractRender170(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER170, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender180
   */
  public Boolean getExtractRender180()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER180);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender180
   */
  public void setExtractRender180(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER180, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender190
   */
  public Boolean getExtractRender190()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER190);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender190
   */
  public void setExtractRender190(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER190, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender200
   */
  public Boolean getExtractRender200()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER200);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender200
   */
  public void setExtractRender200(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER200, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender210
   */
  public Boolean getExtractRender210()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER210);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender210
   */
  public void setExtractRender210(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER210, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender220
   */
  public Boolean getExtractRender220()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER220);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender220
   */
  public void setExtractRender220(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER220, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender230
   */
  public Boolean getExtractRender230()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER230);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender230
   */
  public void setExtractRender230(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER230, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender240
   */
  public Boolean getExtractRender240()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER240);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender240
   */
  public void setExtractRender240(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER240, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender250
   */
  public Boolean getExtractRender250()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER250);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender250
   */
  public void setExtractRender250(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER250, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender260
   */
  public Boolean getExtractRender260()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER260);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender260
   */
  public void setExtractRender260(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER260, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender270
   */
  public Boolean getExtractRender270()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER270);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender270
   */
  public void setExtractRender270(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER270, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender280
   */
  public Boolean getExtractRender280()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER280);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender280
   */
  public void setExtractRender280(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER280, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender290
   */
  public Boolean getExtractRender290()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER290);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender290
   */
  public void setExtractRender290(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER290, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender300
   */
  public Boolean getExtractRender300()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER300);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender300
   */
  public void setExtractRender300(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER300, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender310
   */
  public Boolean getExtractRender310()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER310);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender310
   */
  public void setExtractRender310(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER310, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender320
   */
  public Boolean getExtractRender320()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER320);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender320
   */
  public void setExtractRender320(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER320, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender330
   */
  public Boolean getExtractRender330()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER330);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender330
   */
  public void setExtractRender330(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER330, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender340
   */
  public Boolean getExtractRender340()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER340);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender340
   */
  public void setExtractRender340(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER340, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender350
   */
  public Boolean getExtractRender350()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER350);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender350
   */
  public void setExtractRender350(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER350, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender360
   */
  public Boolean getExtractRender360()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER360);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender360
   */
  public void setExtractRender360(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER360, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender370
   */
  public Boolean getExtractRender370()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER370);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender370
   */
  public void setExtractRender370(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER370, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender380
   */
  public Boolean getExtractRender380()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER380);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender380
   */
  public void setExtractRender380(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER380, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender390
   */
  public Boolean getExtractRender390()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER390);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender390
   */
  public void setExtractRender390(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER390, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender400
   */
  public Boolean getExtractRender400()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER400);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender400
   */
  public void setExtractRender400(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER400, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender500
   */
  public Boolean getExtractRender500()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER500);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender500
   */
  public void setExtractRender500(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER500, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender510
   */
  public Boolean getExtractRender510()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER510);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender510
   */
  public void setExtractRender510(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER510, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender520
   */
  public Boolean getExtractRender520()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER520);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender520
   */
  public void setExtractRender520(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER520, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender530
   */
  public Boolean getExtractRender530()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER530);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender530
   */
  public void setExtractRender530(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER530, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender540
   */
  public Boolean getExtractRender540()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER540);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender540
   */
  public void setExtractRender540(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER540, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender550
   */
  public Boolean getExtractRender550()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER550);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender550
   */
  public void setExtractRender550(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER550, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender560
   */
  public Boolean getExtractRender560()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER560);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender560
   */
  public void setExtractRender560(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER560, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender570
   */
  public Boolean getExtractRender570()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER570);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender570
   */
  public void setExtractRender570(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER570, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender580
   */
  public Boolean getExtractRender580()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER580);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender580
   */
  public void setExtractRender580(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER580, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender590
   */
  public Boolean getExtractRender590()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER590);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender590
   */
  public void setExtractRender590(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER590, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender600
   */
  public Boolean getExtractRender600()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER600);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender600
   */
  public void setExtractRender600(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER600, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender610
   */
  public Boolean getExtractRender610()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER610);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender610
   */
  public void setExtractRender610(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER610, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender620
   */
  public Boolean getExtractRender620()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER620);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender620
   */
  public void setExtractRender620(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER620, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender630
   */
  public Boolean getExtractRender630()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER630);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender630
   */
  public void setExtractRender630(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER630, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender640
   */
  public Boolean getExtractRender640()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER640);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender640
   */
  public void setExtractRender640(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER640, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender650
   */
  public Boolean getExtractRender650()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER650);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender650
   */
  public void setExtractRender650(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER650, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender660
   */
  public Boolean getExtractRender660()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER660);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender660
   */
  public void setExtractRender660(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER660, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender670
   */
  public Boolean getExtractRender670()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER670);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender670
   */
  public void setExtractRender670(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER670, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender680
   */
  public Boolean getExtractRender680()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER680);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender680
   */
  public void setExtractRender680(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER680, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender690
   */
  public Boolean getExtractRender690()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER690);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender690
   */
  public void setExtractRender690(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER690, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender700
   */
  public Boolean getExtractRender700()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER700);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender700
   */
  public void setExtractRender700(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER700, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender710
   */
  public Boolean getExtractRender710()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER710);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender710
   */
  public void setExtractRender710(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER710, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender720
   */
  public Boolean getExtractRender720()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER720);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender720
   */
  public void setExtractRender720(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER720, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender730
   */
  public Boolean getExtractRender730()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER730);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender730
   */
  public void setExtractRender730(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER730, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender740
   */
  public Boolean getExtractRender740()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER740);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender740
   */
  public void setExtractRender740(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER740, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender750
   */
  public Boolean getExtractRender750()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER750);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender750
   */
  public void setExtractRender750(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER750, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender760
   */
  public Boolean getExtractRender760()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER760);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender760
   */
  public void setExtractRender760(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER760, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender770
   */
  public Boolean getExtractRender770()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER770);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender770
   */
  public void setExtractRender770(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER770, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender780
   */
  public Boolean getExtractRender780()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER780);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender780
   */
  public void setExtractRender780(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER780, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender410
   */
  public Boolean getExtractRender410()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER410);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender410
   */
  public void setExtractRender410(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER410, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender420
   */
  public Boolean getExtractRender420()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER420);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender420
   */
  public void setExtractRender420(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER420, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender430
   */
  public Boolean getExtractRender430()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER430);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender430
   */
  public void setExtractRender430(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER430, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender440
   */
  public Boolean getExtractRender440()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER440);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender440
   */
  public void setExtractRender440(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER440, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender450
   */
  public Boolean getExtractRender450()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER450);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender450
   */
  public void setExtractRender450(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER450, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender460
   */
  public Boolean getExtractRender460()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER460);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender460
   */
  public void setExtractRender460(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER460, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender470
   */
  public Boolean getExtractRender470()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER470);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender470
   */
  public void setExtractRender470(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER470, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender480
   */
  public Boolean getExtractRender480()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER480);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender480
   */
  public void setExtractRender480(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER480, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender490
   */
  public Boolean getExtractRender490()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER490);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender490
   */
  public void setExtractRender490(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER490, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender790
   */
  public Boolean getExtractRender790()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER790);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender790
   */
  public void setExtractRender790(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER790, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExtractRender800
   */
  public Boolean getExtractRender800()
  {
    return (Boolean)getAttributeInternal(EXTRACTRENDER800);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExtractRender800
   */
  public void setExtractRender800(Boolean value)
  {
    setAttributeInternal(EXTRACTRENDER800, value);
  }



}