%{

		/*	We declare the global variables and code the grammar that our language will follow   */
		/*  Grammar definition is an important part of any compiler as any string not grammatically corrent will not be processed further */
		/*  Semantic Analysis of string is done here line by line for entire test.c */
#include <stdio.h>
#include "function.cpp"
#include <fstream>
int yylex(void);
void yyerror (const char *s);
extern int yylineno ;

int scope = 0, offset = 0, syn_flag = 0, sem_flag = 0;
vector<entry> function_table;
vector<list_var> global_table;
vector<list_var> struct_var_table;
vector<list_struct> struct_table;
vector<int> dim_list;
vector<list_var> patch_list;
entry *active_func_ptr;
entry *call_name_ptr = NULL;
vector<list_var> param_list;
list_var param_temp;
entry func_temp;


int temp_temp=-1;



int next_quad=0;
vector<string *> quadruples;
vector<int> make_list;
vector<int> arr_dim;



%}

 %define parse.error verbose 
%union { int num; char str[100];float flt;struct Node* node;} 																								/* types of token */

%start code
/* %define parse.error verbose */
%token STRING INTVAL FLTVAL
%token <node> INCLUDE DEFINE FLOAT CHAR INT STRUCT TYPEDEF CONST IF ELSE WHILE FOR BREAK DEFAULT CONTINUE EXTERN RETURN
%token <node> VOID NULLX STATIC ENUM LITRAL GTE_OPE LTE_OPE EQL_OPE NTE_OPE ADD_OPE SUB_OPE MUL_OPE
%token  <node> DIV_OPE INC_OPE DEC_OPE LEF_OPE RGT_OPE AND_OPE OR_OPE PTR_OPE
%token <node> '+' '-' '/' '*' '%' '(' ')' '{' '}' '[' ']' '=' '&' ',' '>' '<' '.' ';'


%type <str> STRING
%type <num> INTVAL
%type <flt> FLTVAL
%type <node> code parts struct var_declare function_head function_body var_declarations opt_string element struct_declare data_type %type <node> struct_elem_list elements_name decl_elem expr square_brackets array_list struct_element mul_star body result element_name %type <node> params_list param_list param stmts stmt return_stmt expr_stmt while_loop function_call arg_list error function_head1 LHS lhs_element  while_lhs  function_call_lhs function_call_rhs if_expr  M N struct_define


	/* left and right associate nature of operators are defined here */
%right ELSE
%left ','
%right '=' ADD_OPE SUB_OPE MUL_OPE DIV_OPE
%right TER_OPE
%left OR_OPE 							
%left AND_OPE
%left EQL_OPE NTE_OPE
%left '>' '<' LTE_OPE GTE_OPE
%left LEF_OPE RGT_OPE
%left '+' '-'
%left '*' '/' '%'
%right '&'
%left '(' ')' '[' ']' '.' PTR_OPE


		/* Whenever a keyword is identified by lex we perform certain functions declared in function.cpp */
		/* What to do of each keyword is piggybacked in code just after the literal is detected inside '{ }' */ 
%%
	
code 				: parts 				{ print_global_table(&global_table);print_quadruples(quadruples);}
					| code parts 			{ print_global_table(&global_table);print_quadruples(quadruples);}
					| code error 				{ syn_flag = 1;}
					| error 					{ syn_flag = 1; $$ = NULL;}
					;

parts				: struct 				
					| struct_define ';'		
					| var_declare 			
					| function_head1 ';'		{ 
												if(!(search_function(&(function_table),func_temp.func_name)))
												{
													function_table.push_back(func_temp);
												}
												else
												{
													ofstream f;
													f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: Function Prototype already exists.Near line number : "<<yylineno;
													sem_flag=1;
													$$->type=ERROR;
												}
												scope=0;
											}
					| function_head function_body { 
													if(active_func_ptr!=NULL)
													{
														delete_var_list(active_func_ptr,scope);
													}

													active_func_ptr=NULL;											
													scope=0; }
					;





struct 				: STRUCT STRING '{' var_declarations '}' opt_string ';'
{
							if((search_struct(&struct_table, $2)))
							{
								std::ofstream f;
f.open("Error.txt",std::ofstream::app);
								f << "\nERROR: Struct " << $2 << " already is defined. Near line number : "<<yylineno ; 
							}
							else
							{
								$$ = new Node; structure k($2, 0);
								for( int i = 0; i < struct_var_table.size(); i++)
								{
									k.mem_list.push_back(struct_var_table[i]);
								}
								struct_table.push_back(k);
								//f << "pushed " << k.name << " in struct_table.Near line number : "<<yylineno ;
								if( ($6) )
								{
									if(!search_global_var(global_table, $6->name))
									{
										variable p($6->name,STRUCT1,SIMPLE,0);
										p.str_ptr = &struct_table[struct_table.size() - 1];
										global_table.push_back(p);
									}
									else
									{
										std::ofstream f;
f.open("Error.txt",std::ofstream::app);
										f << "\nERROR: Variable with name " << $6->name << " already present in global table.Near line number : "<<yylineno;
									}
								}
							}
							struct_var_table.clear();
						}
					;

opt_string 			: {$$ = NULL;}
					| STRING 
						{
							$$  = new Node; $$->name = $1;
						}
					;


var_declarations 	: {$$ = NULL;}
					| var_declarations struct_declare
					;

struct_declare 		: data_type struct_elem_list ';'
						{
							for(int i=0; i<patch_list.size(); i++)
								{
									if(!search_str_var(struct_var_table, patch_list[i].name))
									{
										//f << "pushing " << patch_list[i].name << " in struct_var_table. Near line number : "<<yylineno ;
										patch_list[i].dtype = $1->type;
										struct_var_table.push_back(patch_list[i]);
									}
									else
									{
										std::ofstream f;
f.open("Error.txt",std::ofstream::app);
									f << "\nERROR: Struct object has already been declared." << endl;
									}
								}
								patch_list.clear();	
						}
					| struct 
						{
						//has to do this too.
						}
					;

struct_elem_list 	: element
					| struct_elem_list ',' element
					;

var_declare 		: data_type elements_name ';' 
{
	if(!scope)
	{
		for(int i=0; i<patch_list.size(); i++)
		{
			if(!search_global_var(global_table, patch_list[i].name))
			{
				if ( patch_list[i].dtype == NONE || coercible(patch_list[i].dtype, $1->type))
				{
					patch_list[i].dtype = $1->type;
					if($1->type == STRUCT1)
					{
						list_struct *temp;
						if((temp = search_struct(&struct_table, $1->str_name)))
						{
							patch_list[i].str_ptr = temp;
							patch_list[i].vtype=SIMPLE;
							global_table.push_back(patch_list[i]);
						}
						else
						{
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f << "ERROR : Struct " << $1->str_name << " does not exist.Near line number : "<<yylineno;
						}
					}
					else
					{	
						global_table.push_back(patch_list[i]);
						//try for expr equality
						if(patch_list[i].ref != -1){
							list_var t=global_table[patch_list[i].ref];
							if(!coercible(patch_list[i].dtype,t.dtype) || !comapatible_arithop(patch_list[i].dtype,t.dtype)){
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
								if(!coercible(patch_list[i].dtype,t.dtype))
									f<<"\nERROR: Assigning Incompatible data type.Near line number : "<<yylineno;
								else
									f<<"\nWarning: Assigning different data type.Near line number : "<<yylineno;
								sem_flag=1;
								$$->type==ERROR;
							}
							else{
								gen(next_quad,&quadruples, global_table.back().name + " = " +t.name);
								next_quad++;
							}
						}
					}
				}
				else
				{
					std::ofstream f;
f.open("Error.txt",std::ofstream::app);
					f << "\nERROR: Incompatible data type assignment -" << patch_list[i].dtype << " = " << $1->type << endl;
				}
			}
			else
			{
			std::ofstream f;
f.open("Error.txt",std::ofstream::app);
			f << "\nERROR: Variable " << patch_list[i].name << " has already been defined in global scope." << endl;
			}
		}
	}
	else
	{
		
		for(int i=0;i<patch_list.size();i++)
		{
			list_var* found = search_var(patch_list[i].name,active_func_ptr,scope);
			if(found && found->level == scope)
			{
					std::ofstream f;
f.open("Error.txt",std::ofstream::app);
					f << "\nERROR: Variable has already been declared in the same scope.Near line number : "<<yylineno;
					$$->type=ERROR;
					sem_flag=1;
			}
			else if(scope ==2)
			{
				found = search_param(patch_list[i].name,active_func_ptr);
				if(found)
				{
					std::ofstream f;
f.open("Error.txt",std::ofstream::app);
					f << "\nERROR: Variable already present in parameter list.Near line number : "<<yylineno;
					$$->type=ERROR;
					sem_flag=1;
				}
				else 
				{	
					if(active_func_ptr){
						patch_list[i].dtype = $1->type;
						if($1->type == STRUCT1)
						{
							list_struct *temp;
							if((temp = search_struct(&struct_table, $1->str_name)))
							{
								patch_list[i].str_ptr = temp;
								patch_list[i].vtype=SIMPLE;
								active_func_ptr->var_list.push_back(patch_list[i]);
							}
							else
							{
								std::ofstream f;
f.open("Error.txt",std::ofstream::app);
								f << "\nERROR: Struct " << $1->str_name << " has not been defined.Near line number : "<<yylineno;
							}
						}
						else
						{
						active_func_ptr->var_list.push_back(patch_list[i]);
						//try for expr equality
						if(patch_list[i].ref != -1){
							list_var t=global_table[patch_list[i].ref];
							if(!coercible(patch_list[i].dtype,t.dtype) || !comapatible_arithop(patch_list[i].dtype,t.dtype)){
								std::ofstream f;
f.open("Error.txt",std::ofstream::app);
								if(!coercible(patch_list[i].dtype,t.dtype))
									f<<"\nERROR: Assigning Incompatible data type.Near line number : "<<yylineno;
								else
									f<<"\nWarning: Assigning different data type.Near line number : "<<yylineno;
								sem_flag=1;
								$$->type==ERROR;
							}
							else{
								gen(next_quad,&quadruples, active_func_ptr->var_list.back().name + " = " +t.name);
								next_quad++;
							}
							}
						}
					}
				}				
			}
			else
			{	
			if(active_func_ptr){
				patch_list[i].dtype = $1->type;
				if($1->type == STRUCT1)
					{
						list_struct *temp;
						if((temp = search_struct(&struct_table, $1->str_name)))
						{
							patch_list[i].str_ptr = temp;
							patch_list[i].vtype=SIMPLE;
							active_func_ptr->var_list.push_back(patch_list[i]);
						}
						else
						{
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f << "\nERROR: Struct " << $1->str_name << " has not been defined.Near line number : "<<yylineno;
						}
					}
					else
					{
						active_func_ptr->var_list.push_back(patch_list[i]);
						//try for expr equality
						if(patch_list[i].ref != -1){
							list_var t=global_table[patch_list[i].ref];
							if(!coercible(patch_list[i].dtype,t.dtype) || !comapatible_arithop(patch_list[i].dtype,t.dtype)){
								std::ofstream f;
f.open("Error.txt",std::ofstream::app);
								if(!coercible(patch_list[i].dtype,t.dtype))
									f<<"\nERROR: Assigning Incompatible data type.Near line number : "<<yylineno;
								else
									f<<"\nWarning: Assigning different data type.Near line number : "<<yylineno;
								sem_flag=1;
								$$->type==ERROR;
						}
						else{
							gen(next_quad,&quadruples, active_func_ptr->var_list.back().name + " = " +t.name);
							next_quad++;
						}
						}
					}
				}
			}
		}
	}
	patch_list.clear();
}
					;


result 		 		: VOID 			{ $$ = new Node; $$->type = VOID1; }
					;

data_type 			: INT 			{ $$ = new Node; $$->type = INT1;}
					| CHAR 			{ $$ = new Node; $$->type = CHAR1; }
					| FLOAT 		{ $$ = new Node; $$->type = FLOAT1; }
					| STRUCT STRING { $$ = new Node; $$->type = STRUCT1; $$->str_name = $2; }
					;


elements_name 		: decl_elem 		
					| elements_name ',' decl_elem
					;

decl_elem 			: element
					| STRING '=' expr 
								{	if($3->type != ERROR){
										 $$ = new Node; $$->name = $1; data_type type = $3->type ; variable k($$->name, type, SIMPLE, scope);
										 k.ref=$3->result_int;
									 	 patch_list.push_back(k);
								 	}
								 	else{
								 		$$=new Node; $$->type=ERROR;
								 	}
								 }
					| mul_star STRING '=' expr 
					;

struct_define		: struct_element '=' expr 
												{ $$=new Node;
													if($1->type !=ERROR && $3->type!=ERROR){
														if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
														std::ofstream f;
f.open("Error.txt",std::ofstream::app);
																if(!coercible($1->type,$3->type))
																	f<<"\nERROR: Comparing Incompatible data types.Near line number : "<<yylineno;
																else
																	f<<"\nWarning: Comparing different data types.Near line number : "<<yylineno;
																sem_flag=1;
																$$->type==ERROR;
														}
														else{
															$$->type=$1->type;
															gen(next_quad,&quadruples, global_table[$1->place_int].name+ "." + $1->str_name + " = " +global_table[$3->result_int].name);
															next_quad++;
															//f<<"Readched hereNear line number : "<<yylineno;
														}
													}
													else{
															
															$$->type=ERROR;
															sem_flag=1;
															}
												}	
					;

element 			: element_name 
					| mul_star element_name  
					;					



element_name 		: STRING { $$ = new Node; $$->name = $1; variable k($$->name, NONE, SIMPLE, scope); 
								k.ref=-1;
							   patch_list.push_back(k);
							 }
					| STRING square_brackets 
											{ $$ = new Node; $$->name = $1; variable k($$->name, NONE, ARRAY, scope); 
												k.ref=-1;
												for (size_t i = 0; i < dim_list.size(); i++) 
												{
											        k.dimlist.push_back(dim_list[i]);
											    }
											    dim_list.clear();
											    arr_dim.clear();
											    patch_list.push_back(k);
											}
					;

array_list 			: expr 			{	$$ = new Node;
										$$->val.a = 1;
										//f<<"type: "<<$1->type;
										if(!check_param_type(call_name_ptr, 1, $1->type))
										{
											std::ofstream f;
f.open("Error.txt",std::ofstream::app);
											f << "\nERROR: Incompatible parameter data type.Near line number : "<<yylineno;
											sem_flag = 1;
											$$->type = ERROR;
										}
										else{
											gen(next_quad,&quadruples, "param "+ global_table[$1->result_int].name);
											next_quad++;
										}

									}
					| array_list ',' expr 	{	$$ = new Node;
												$$->val.a = $1->val.a + 1;
												if(!check_param_type(call_name_ptr, $$->val.a, $3->type))
												{
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: Incompatible parameter data type.Near line number : "<<yylineno;
													sem_flag = 1;
													$$->type = ERROR;
												}
												else{
												gen(next_quad,&quadruples, "param "+ global_table[$3->result_int].name);
												next_quad++;
											}
											}
					;

square_brackets 	: '[' expr ']'  
						{
						$$ = new Node;
						if($2->type == INT1)
						{	
							dim_list.push_back($2->val.a);	
							arr_dim.push_back($2->result_int);
						}
						else
						{	
							$$->type = ERROR;
							sem_flag = 1;
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f << "\nERROR: Invalid memory access." << endl;
						}
						}
					| '[' expr ']' square_brackets
						{
						$$ = new Node;
						if($2->type == INT1)
						{
							dim_list.insert(dim_list.begin(), $2->val.a);	
							arr_dim.insert(arr_dim.begin(), $2->result_int);
						}
						else
						{
							$$->type = ERROR;
							sem_flag = 1;
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f << "\nERROR: Invalid memory access." << endl;
						}
						}

					;

mul_star 			: '*'
					| '*' mul_star
					;

function_body 		: '{' body '}' 					{ 
														if(active_func_ptr){
															if($2){
																back_patch($2->next,next_quad,&quadruples);
															}
															gen(next_quad,&quadruples, "func end");
															next_quad++;
														}								
					
													}
					;

function_head 		: result STRING '(' params_list ')' {  $$ = new Node;
														  function k($2,$1->type); 
														  for(int i=0;i<param_list.size();i++){
															  k.param_list.push_back(param_list[i]);
															}
															k.num_param=param_list.size();
															k.defined=1;
															entry* found = search_function(&(function_table),k.func_name);
															if(found)
															{
																int count_flag=0;
																for(int i=0;i<k.param_list.size();i++)
																{
																	int flag=0;
																	for(int j=0;j<found->param_list.size();j++)
																	{
																		if(k.param_list[i].name==found->param_list[j].name && k.param_list[i].dtype ==found->param_list[j].dtype )
																		{
																			flag=1;
																		}
																	}
																	if (flag==1)
																		count_flag++;
																}
																if(count_flag==found->param_list.size())
																{	
																	if(found->defined==1){
																		std::ofstream f;
f.open("Error.txt",std::ofstream::app);
																		f << "\nERROR : Function has already been definedNear line number : "<<yylineno;
																	$$->type=ERROR;
																	sem_flag=1;
																	}
																	else{
																	found->defined=1;
																	active_func_ptr = found;
																	gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																	next_quad++;
																	}
																	
																}
																else{	
																	function_table.push_back(k);
																	active_func_ptr = &(function_table.back());
																	gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																	next_quad++;
																}

															}
															else
															{
																function_table.push_back(k);
																active_func_ptr = &(function_table.back());
																gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																next_quad++;
															}
															param_list.clear();
															scope=2;
														  }
					| data_type STRING '(' params_list ')'  {  $$ = new Node;
														  function k($2,$1->type); 
														  for(int i=0;i<param_list.size();i++){
															  k.param_list.push_back(param_list[i]);
															}
															k.num_param=param_list.size();
															k.defined=1;
															entry* found = search_function(&(function_table),k.func_name);
															
															if(found)
															{	
																int count_flag=0;
																
																for(int i=0;i<k.param_list.size();i++)
																{
																	int flag=0;
																	for(int j=0;j<(found->param_list).size();j++)
																	{	
																		if(k.param_list[i].name==(found->param_list[j]).name && k.param_list[i].dtype ==(found->param_list[j]).dtype )
																		{
																			flag=1;
																		}
																	}
																	if (flag==1)
																		count_flag++;
																}
																if(count_flag==(found->param_list).size())
																{	
																	if(found->defined==1){
																		std::ofstream f;
f.open("Error.txt",std::ofstream::app);
																		f << "\nERROR : Function has already been definedNear line number : "<<yylineno;
																	$$->type=ERROR;
																	sem_flag=1;
																	}
																	else{
																	found->defined=1;
																	active_func_ptr = found;
																	gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																	next_quad++;
																	}
																}
																else
																{
																	function_table.push_back(k);
																	active_func_ptr = &(function_table.back());
																	gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																	next_quad++;
																	
																}

															}
															else
															{
																function_table.push_back(k);
																active_func_ptr = &(function_table.back());
																gen(next_quad,&quadruples, "funcc begin: "+ active_func_ptr->func_name);
																next_quad++;

															}
															param_list.clear();
															scope=2;
														  }
					| result mul_star STRING '(' params_list ')' 
					| data_type mul_star STRING '(' params_list ')'
					;

function_head1 		: result STRING '(' params_list ')' {  
														  function k($2,$1->type); 
														  for(int i=0;i<param_list.size();i++){
															  k.param_list.push_back(param_list[i]);
															}
															k.num_param=param_list.size();
															k.defined=0;
															func_temp=k;
															param_list.clear();
															scope=2;
														  }
					| data_type STRING '(' params_list ')' { 
														  function k($2,$1->type); 
														  for(int i=0;i<param_list.size();i++){
															  k.param_list.push_back(param_list[i]);
															}
															k.num_param=param_list.size();
															k.defined=0;
															func_temp=k;
															param_list.clear();
														  	 scope=2;
														  }
					| result mul_star STRING '(' params_list ')' 
					| data_type mul_star STRING '(' params_list ')'
					;

params_list 		: {$$ = NULL;}
					| param_list 		
					| VOID 				{$$ = NULL;}
					;

param_list 			: param   			{ param_list.push_back(param_temp);}
					| param_list ',' param {
											int flag=0;
											for(int i=0;i<param_list.size();i++)
											{
												if(param_list[i].name == param_temp.name)
												{
													flag=1;
													sem_flag=1;
													$$->type==ERROR;
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: Parameter with same name already present used in the parameter list.Near line number : "<<yylineno; 
												}
											}
												if(flag==0)
											 		param_list.push_back(param_temp); 
											}
											

param 				: data_type element  { 
											patch_list[0].dtype = $1->type; 
											param_temp=patch_list[0];
											param_temp.level=1;
											patch_list.clear();  
										}
					;

body 				: { $$ = NULL; }
					| body M stmts    						
							{ 
								$$=new Node;
								if($1)
									back_patch($1->next,$2->quad,&quadruples);
								$$->next=$3->next;
							}
					;

stmts 				: stmt
					{	$$=new Node;
						$$->next=$1->next;}
					| if_expr ')' stmts {
								vector <int> temp;
								temp.push_back($1->falselist);
								$$->next=merge(temp,$3->next);
					}

					| if_expr ')' stmt N ELSE M stmts{
							vector<int> temp;
							temp.push_back($1->falselist);
							back_patch(temp,$6->quad,&quadruples);
							vector<int> temp2=merge($3->next,$7->next);
							$$->next=merge($4->next,temp2);
					}
					;

N 					: 	 {$$=new Node; 
						 ($$->next).push_back(next_quad);
						 gen(next_quad,&quadruples, "goto ");
						 next_quad++;  }
					;


M 					:   {$$=new Node;
						 $$->quad=next_quad;
						}


if_expr 			: IF '(' expr 
					{  $$= new Node; 
						if($3->type ==ERROR || $3->type==NONE) {
							std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f<<"\nERROR: Invalid condition in if statement.";
							$$->type=ERROR;
							sem_flag=1;
						}
						else{
							$$->falselist=next_quad;
							gen(next_quad,&quadruples, "if "+ global_table[$3->result_int].name + " <= 0 goto");
							next_quad++;
						}

					 }				 
					;


stmt 				: '{' {scope++;} body '}' {	$$=new Node;
												$$->next=$3->next;
												if(active_func_ptr)
													delete_var_list(active_func_ptr,scope) ;
												scope--;} 
					| return_stmt 	{$$=new Node; gen(next_quad,&quadruples, "return "+ global_table[$1->result_int].name);   next_quad++; $$->next.clear();}
					| expr_stmt    {$$=new Node; $$->next=$1->next;}
					| while_loop   
					| var_declare 
					;

return_stmt 		: RETURN ';' { $$=new Node;
								//f<<"asdas"<<endl;
								if(active_func_ptr && !(active_func_ptr->func_type == VOID1))
									{
											sem_flag=1;
											$$->type==ERROR;
											std::ofstream f;
f.open("Error.txt",std::ofstream::app);
											f << "\nERROR: Incompatible data type used in return statement.Near line number : "<<yylineno;  
									}
								}
					| RETURN expr ';'
								{ $$=new Node;
								//f<<"here: "<< $2->type<<endl;
								if(active_func_ptr && !(active_func_ptr->func_type == $2->type))
									{
											sem_flag=1;
											$$->type==ERROR;
											std::ofstream f;
f.open("Error.txt",std::ofstream::app);
											f << "\nERROR: Incompatible data type used in return statement.Near line number : "<<yylineno;  
									}
									else
										$$->result_int=$2->result_int;
								}
					;

expr_stmt 			: ';'           {$$=new Node; ($$->next).push_back(next_quad);}
					| expr ';'		{$$=new Node; $$->next = $1->next; $$->type=$1->type; $$->result_int=$1->result_int	; }
					;


expr 				: expr EQL_OPE expr  	{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Comparing Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Comparing different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " == " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| LHS ADD_OPE expr
										{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													if($1->offset_int ==-1)
													{	gen(next_quad,&quadruples,  global_table[$1->place_int].name+ " += "+  global_table[operand2].name);
														next_quad++;
													}
													else{
													gen(next_quad,&quadruples, global_table[$3->place_int].name+ "["+ global_table[$3->offset_int].name+  "] += " + global_table[operand2].name);
													next_quad++;
													}

												}

											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| LHS SUB_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													if($1->offset_int==-1)
													{	gen(next_quad,&quadruples,  global_table[$1->place_int].name+ " -= "+  global_table[operand2].name);
														next_quad++;
													}
													else{
													gen(next_quad,&quadruples, global_table[$3->place_int].name+ "["+ global_table[$3->offset_int].name+  "] += " + global_table[operand2].name);
													next_quad++;
													}

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| LHS MUL_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													if($1->offset_int==-1)
													{	gen(next_quad,&quadruples,  global_table[$1->place_int].name+ " *= "+  global_table[operand2].name);
														next_quad++;
													}
													else{
													gen(next_quad,&quadruples, global_table[$3->place_int].name+ "["+ global_table[$3->offset_int].name+  "] += " + global_table[operand2].name);
													next_quad++;
													}

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
				 	| LHS DIV_OPE expr
				 								{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													if($1->offset_int==-1)
													{	gen(next_quad,&quadruples,  global_table[$1->place_int].name+ " /= "+  global_table[operand2].name);
														next_quad++;
													}
													else{
													gen(next_quad,&quadruples, global_table[$3->place_int].name+ "["+ global_table[$3->offset_int].name+  "] += " + global_table[operand2].name);
													next_quad++;
													}

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}

					| struct_element ADD_OPE expr 

				 								{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													gen(next_quad,&quadruples,global_table[$1->place_int].name+ "." + $1->str_name+ " /= "+  global_table[operand2].name);
														next_quad++;										
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| struct_element SUB_OPE expr
												{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													gen(next_quad,&quadruples,global_table[$1->place_int].name+ "." + $1->str_name+ " /= "+  global_table[operand2].name);
														next_quad++;										
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}

					| struct_element MUL_OPE expr
												{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													gen(next_quad,&quadruples,global_table[$1->place_int].name+ "." + $1->str_name+ " /= "+  global_table[operand2].name);
														next_quad++;										
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| struct_element DIV_OPE expr

												{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=$1->type;

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand2;
													
										
													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													else if($3->type == FLOAT1 && $$->type== INT1){
														operand2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_int(" +  global_table[$3->result_int].name + ")");
														next_quad++;
													}

													gen(next_quad,&quadruples,global_table[$1->place_int].name+ "." + $1->str_name+ " /= "+  global_table[operand2].name);
														next_quad++;										
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| struct_element '=' expr

											{ $$=new Node;
												if($1->type !=ERROR && $3->type!=ERROR){
													if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
															if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
															sem_flag=1;
															$$->type==ERROR;
													}
													else{
														$$->type=$1->type;												
														gen(next_quad,&quadruples, global_table[$1->place_int].name+ "." + $1->str_name + " = " +global_table[$3->result_int].name);
														next_quad++;
														
													}

												}
												else{
														$$->type=ERROR;
														sem_flag=1;
														}
												}
					| expr GTE_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " >= " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '>' expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " > " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr LTE_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " <= " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '<' expr

											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
											else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " < " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr NTE_OPE expr

											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=BOOL1;

													$$->result_int=newtemp(INT1,&global_table,scope);

													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 1");
													next_quad++;
													gen(next_quad,&quadruples, "if "+ global_table[$1->result_int].name+ " != " + global_table[$3->result_int].name + " goto "+ to_string(next_quad+2) );
													next_quad++;
													gen(next_quad,&quadruples, global_table[$$->result_int].name +" = 0");
													next_quad++;	
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '+' expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=compare_type($1->type,$3->type);

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand1,operand2;
													
													if($1->type == $$->type)
														operand1=$1->result_int;
													else if($1->type == INT1 && $$->type== FLOAT1){
														operand1=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand1].name + "= cnvrt_float(" + global_table[$1->result_int].name + ")");
														next_quad++;
													}

													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													gen(next_quad,&quadruples,global_table[$$->result_int].name+ " = "+  global_table[operand1].name  + " + " +  global_table[operand2].name );
													next_quad++;

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '-' expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=compare_type($1->type,$3->type);

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand1,operand2;
													
													if($1->type == $$->type)
														operand1=$1->result_int;
													else if($1->type == INT1 && $$->type== FLOAT1){
														operand1=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand1].name + "= cnvrt_float(" + global_table[$1->result_int].name + ")");
														next_quad++;
													}

													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													gen(next_quad,&quadruples,global_table[$$->result_int].name+ " = "+  global_table[operand1].name  + " - " +  global_table[operand2].name );
													next_quad++;

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '*' expr

										{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=compare_type($1->type,$3->type);

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand1,operand2;
													
													if($1->type == $$->type)
														operand1=$1->result_int;
													else if($1->type == INT1 && $$->type== FLOAT1){
														operand1=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand1].name + "= cnvrt_float(" + global_table[$1->result_int].name + ")");
														next_quad++;
													}

													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													gen(next_quad,&quadruples,global_table[$$->result_int].name+ " = "+  global_table[operand1].name  + " * " +  global_table[operand2].name );
													next_quad++;

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr '/' expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
												std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
														sem_flag=1;
														$$->type==ERROR;
												}
												else{
													$$->type=compare_type($1->type,$3->type);

													$$->result_int=newtemp($$->type,&global_table,scope);
													int operand1,operand2;
													
													if($1->type == $$->type)
														operand1=$1->result_int;
													else if($1->type == INT1 && $$->type== FLOAT1){
														operand1=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand1].name + "= cnvrt_float(" + global_table[$1->result_int].name + ")");
														next_quad++;
													}

													if($3->type == $$->type)
														operand2=$3->result_int;
													else if($3->type == INT1 && $$->type== FLOAT1){
														operand2=newtemp(FLOAT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[operand2].name + "= cnvrt_float(" + global_table[$3->result_int].name + ")");
														next_quad++;
													}
													gen(next_quad,&quadruples,global_table[$$->result_int].name+ " = "+  global_table[operand1].name  + " / " +  global_table[operand2].name );
													next_quad++;

												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
													}
											}
					| expr LEF_OPE expr 

											{ $$=new Node;
												if($1->type ==INT1 && $3->type==INT1){
													$$->type=$1->type;
												}
												else{
														$$->type=ERROR;
														sem_flag=1;
													}
											}

					| LHS 	 				{
											$$=new Node; $$->type=$1->type;
											if($1->offset_int==-1)
												$$->result_int=$1->place_int;	
											else{
												$$->result_int=newtemp(global_table[$1->place_int].dtype,&global_table,scope);
												
												gen(next_quad,&quadruples, global_table[$$->result_int].name + " = " + global_table[$1->place_int].name + "[" + global_table[$1->offset_int].name + "]");
												next_quad++;
												}
											}
										
					| LHS '=' expr 
												{ $$=new Node;
													
													
													if($1->type !=ERROR && $3->type!=ERROR){
														if(!coercible($1->type,$3->type) || !comapatible_arithop($1->type,$3->type)){
														std::ofstream f;
f.open("Error.txt",std::ofstream::app);
																if(!coercible($1->type,$3->type))
															f<<"\nERROR: Operation cannot be performed on Incompatible data types.Near line number : "<<yylineno;
														else
															f<<"\nWarning: Operation cannot be performed different data types.Near line number : "<<yylineno;
																sem_flag=1;
																$$->type==ERROR;
														}
														else{
															$$->type=$1->type;
															if($1->offset_int==-1)
															{ 	
																gen(next_quad,&quadruples, global_table[$1->place_int].name + " = " +global_table[$3->result_int].name);
																next_quad++;
															}
															else{
																gen(next_quad,&quadruples, global_table[$1->result_int].name + " = " +  global_table[$3->result_int].name);
																next_quad++;
															}	
														}

													}
													else{
															$$->type=ERROR;
															sem_flag=1;
															}
												}
										
					| struct_element
											{
											$$=new Node; $$->type=$1->type;
												$$->result_int=$1->place_int;	
											}
					| expr RGT_OPE expr
											{ $$=new Node;
												if($1->type ==INT1 && $3->type==INT1){
													$$->type=$1->type;
												}
												else{
														$$->type=ERROR;
														sem_flag=1;
													}
											}
					| expr AND_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(($1->type==BOOL1 || $1->type==INT1)&& ($3->type==BOOL1 || $3->type==INT1)){
														$$->type=BOOL1;
														$$->result_int=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[$$->result_int].name + " = " + global_table[$1->result_int].name + " && " + global_table[$3->result_int].name);
														next_quad++;
												}
												else
													{
													$$->type=ERROR;
													sem_flag=1;
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
												}
											}
					| expr OR_OPE expr
											{ $$=new Node;
											if($1->type !=ERROR && $3->type!=ERROR){
												if(($1->type==BOOL1 || $1->type==INT1)&& ($3->type==BOOL1 || $3->type==INT1)){
														$$->type=BOOL1;
														$$->result_int=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[$$->result_int].name + " = " + global_table[$1->result_int].name + " || " + global_table[$3->result_int].name);
														next_quad++;
												}
												else
													{
													$$->type=ERROR;
													sem_flag=1;
												}
											}
											else{
													$$->type=ERROR;
													sem_flag=1;
												}
											}

					| '(' expr ')'		{ $$=new Node; $$->type=$2->type; $$->result_int=$2->result_int;}
				 	| INTVAL 		{ $$ = new Node; 
				 					  $$->val.a = $1;
				 					  $$->type = INT1; 
				 					  $$->result_int=newtemp(INT1,&global_table,scope);
				 					  global_table[$$->result_int].val.a=$1;
				 					  gen(next_quad,&quadruples,global_table[$$->result_int].name + " = " + to_string($$->val.a));
				 					  next_quad++;
				 					 }			
				 	| FLTVAL		{ $$ = new Node; $$->val.b = $1;$$->type = FLOAT1;
				 					  $$->result_int=newtemp(FLOAT1,&global_table,scope);
				 					  gen(next_quad,&quadruples,global_table[$$->result_int].name + " = " + to_string($$->val.a));
				 					  next_quad++;
				 					} 
				 	| function_call  {$$=new Node; $$->type=$1->type; $$->result_int=$1->result_int;  }
				 	;




LHS					: lhs_element	{$$=new Node;
									
										list_var * found=search_var1(param_temp.name,param_temp.vtype,param_temp.dimlist.size(),active_func_ptr,scope);
										std::ofstream f;
f.open("Error.txt",std::ofstream::app);
										if(!found){
											
											found=search_param1(param_temp.name,param_temp.vtype,param_temp.dimlist.size(),active_func_ptr);
											if(!found){
												
												found = search_global_var1(param_temp.name,param_temp.vtype,param_temp.dimlist.size(),&global_table);
												if(!found)
												{
													$$->type=ERROR;
													sem_flag=1;
												}
												else{
													
													$$->type=found->dtype;


													if(found->vtype==SIMPLE)
														{$$->place_int = getindex(found,&global_table);    $$->offset_int =-1;}
													else
													{
														//to calculate offset
														int flag=1;
														for(int i=0;i<found->dimlist.size();i++){
														if(global_table[arr_dim[i]].val.a>= found->dimlist[i])
															{
																flag=0;

																f << " Warning: array access out of bounds!!!!"<<endl;
																break;
															}
														}
														int t=arr_dim[0];
														for(int i=1;i< found->dimlist.size();i++){
															int temp=newtemp(INT1,&global_table,scope);
															gen(next_quad,&quadruples, global_table[temp].name+" = "+global_table[t].name + " * " + to_string(found->dimlist[i]));
															next_quad++;
															int temp2=newtemp(INT1,&global_table,scope);
															gen(next_quad,&quadruples, global_table[temp2].name+" = "+global_table[temp].name + " + " + global_table[arr_dim[i]].name);
															next_quad++;
															t=temp2;
														}
														int temp3=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp3].name+" = "+global_table[t].name+ " * " + to_string(size(found->dtype)));
														next_quad++;
														int temp4=newtemp(found->dtype,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp4].name+" = addr(" + found->name + ")");
														next_quad++;  
														$$->place_int=temp4;
														$$->offset_int=t;
														arr_dim.clear();
													}
												}
											}


											else{

												
												//f<<found->dtype;
												$$->type=found->dtype;
												
												if(found->vtype==SIMPLE)
														{$$->place_int = newtemp(found->dtype,&global_table,scope); $$->offset_int=-1;}
												else
												{
													//to calculate offset
													int flag=1;
													for(int i=0;i<found->dimlist.size();i++){
													if(global_table[arr_dim[i]].val.a>= found->dimlist[i])
														{
															flag=0;
															f << " Warning: array access out of bounds!!!!"<<endl;
															break;
														}
													}
														int t=arr_dim[0];
														for(int i=1;i< found->dimlist.size();i++){
															int temp=newtemp(INT1,&global_table,scope);
															gen(next_quad,&quadruples, global_table[temp].name+" = "+global_table[t].name + " * " + to_string(found->dimlist[i]));
															next_quad++;
															int temp2=newtemp(INT1,&global_table,scope);
															gen(next_quad,&quadruples, global_table[temp2].name+" = "+global_table[temp].name + " + " + global_table[arr_dim[i]].name);
															next_quad++;
															t=temp2;
														}
														int temp3=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp3].name+" = "+global_table[t].name+ " * " + to_string(size(found->dtype)));
														next_quad++;
														int temp4=newtemp(found->dtype,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp4].name+" = addr(" + found->name + ")");
														next_quad++;
														$$->place_int=temp4;
														$$->offset_int=t;
														arr_dim.clear();
												}
											}
										}
										else {
											
											$$->type=found->dtype;
											

												if(found->vtype==SIMPLE)
												{
														$$->place_int = newtemp(found->dtype,&global_table,0); $$->offset_int=-1;

												}

												else
												{	
													//to calculate offset
													int flag=1;
													for(int i=0;i<found->dimlist.size();i++){
														if(global_table[arr_dim[i]].val.a>= found->dimlist[i])
														{
															flag=0;
															f << " Warning: array access out of bounds!!!!  "<<yylineno<<endl;
															break;
														}
													}
													int t=arr_dim[0];
													
													for(int i=1;i< found->dimlist.size();i++){
														
														int temp=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp].name+" = "+global_table[t].name + " * " + to_string(found->dimlist[i]));
														next_quad++;
														int temp2=newtemp(INT1,&global_table,scope);
														gen(next_quad,&quadruples, global_table[temp2].name+" = "+global_table[temp].name + " + " + global_table[arr_dim[i]].name);
														next_quad++;
														t=temp2;
													}
													
													int temp3=newtemp(INT1,&global_table,scope);
													
													gen(next_quad,&quadruples, global_table[temp3].name+" = "+global_table[t].name+ " * " + to_string(size(found->dtype)));
													next_quad++;

													int temp4=newtemp(found->dtype,&global_table,scope);
													
													gen(next_quad,&quadruples, global_table[temp4].name+" = addr(" + found->name + ")");
													next_quad++;
													$$->place_int=temp4;
													$$->offset_int=t;
													arr_dim.clear();

												}
										}
									}
					| mul_star lhs_element 
					;					


lhs_element			: STRING { $$ = new Node; $$->name = $1; param_temp.name=$1; param_temp.vtype=SIMPLE;}
					| STRING square_brackets 
						{ $$ = new Node; $$->name = $1; 
							param_temp.name=$1; param_temp.vtype=ARRAY;
							for (size_t i = 0; i < dim_list.size(); i++) 
							{
						        param_temp.dimlist.push_back(dim_list[i]);
						    }
						    dim_list.clear();
						}


while_loop 			:while_lhs   ')' stmt
					{
						$$=new Node;
						gen(next_quad,&quadruples, "goto "+ $1->begin);
						next_quad++;
						back_patch($3->next,$1->begin,&quadruples);
						($$->next).push_back($1->falselist);
					}
					;




while_lhs			:WHILE M '(' expr
					{  $$= new Node; 
						if($4->type ==ERROR || $4->type==NONE) {
						std::ofstream f;
f.open("Error.txt",std::ofstream::app);
							f<<"\nERROR: Invalid condition in While loopNear line number : "<<yylineno;
							$$->type=ERROR;
							sem_flag=1;
						}
						else{
							$$->falselist=next_quad;
							gen(next_quad,&quadruples, "if "+ global_table[$4->result_int].name + " <= 0 goto" );
							next_quad++;
							$$->begin=$2->quad;
						}

					 }
					;





function_call 		: function_call_lhs function_call_rhs {$$=new Node; $$->result_int=$2->result_int; $$->type=$2->type;}
					;



function_call_lhs 	: STRING {				$$ = new Node; $$->name = $1;
												entry *found = search_function(&function_table, $1);
												if(found)
												{	//f<<"Function found: "<<found->func_name<<endl;
													call_name_ptr = found;
												}
												else
												{
													call_name_ptr = NULL;
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: Function " << $1 << " not defined.Near line number : "<<yylineno;
													$$->type = ERROR;
													sem_flag = 1;
												}
											}

					;


function_call_rhs	:'(' arg_list ')' 	{ 	$$=new Node;
											if(call_name_ptr){
												if(call_name_ptr->num_param != $2->val.a )
												{
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: Incorrect number of parameters " << call_name_ptr->num_param << " != " << $2->val.a << endl;
												}
												else{
													//f<<"here Near line number : "<<yylineno;
													
													int temp=newtemp(call_name_ptr->func_type,&global_table,scope);
													gen(next_quad,&quadruples, "refparam " + global_table[temp].name);
													next_quad++;
													gen(next_quad,&quadruples, "call "+ call_name_ptr->func_name + ", " + to_string(call_name_ptr->num_param+1));
													next_quad++;
													$$->result_int=temp;
													
													$$->type= global_table[temp].dtype;
													
												}
											}
											else
												$$->type=ERROR;
											
										}
					;

arg_list			: {$$ = new Node; $$->val.a=0; }	
					| array_list 	{ $$ = new Node; 	
									  $$->val.a = $1->val.a;
									}
					;


struct_element 		: STRING '.' STRING 	{	$$ = new Node;
												list_var *temp;
												if((temp = search_struct_in_func_table($1, active_func_ptr, scope)))
												{	
												//f<<"\n found the struct in functable"<<endl;
													int _flag = 0,z = temp->str_ptr->mem_list.size();
													for(int i=0; i<z; i++)
													{
														if(temp->str_ptr->mem_list[i].name == ($3))
														{
															$$->type = temp->str_ptr->mem_list[i].dtype;
															_flag = 1;
															$$->place_int=newtemp($$->type,&global_table,scope);
															$$->str_name=$3;
															break;

														}
													}
													if(_flag == 0)
													{
														std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														f << "\nERROR: No attribute ' " << $3 << " ' in struct ' " << $1 << " ' found.Near line number : "<<yylineno;
														$$->type = ERROR;
														sem_flag = 1;
													}
												}
												else if((temp = search_struct_in_global($1, &global_table)))
												{
													//f<<"\n found the struct in globtable"<<endl;
													int _flag = 0;
													int z = temp->str_ptr->mem_list.size();
													for(int i=0; i<z; i++)
													{
														if(temp->str_ptr->mem_list[i].name == ($3))
														{
															$$->type = temp->str_ptr->mem_list[i].dtype;
															_flag = 1;
															$$->place_int=getindex(temp,&global_table);
															$$->str_name=$3;
															break;
														}
													}
													if(_flag == 0)
													{
														std::ofstream f;
f.open("Error.txt",std::ofstream::app);
														f << "\nERROR: No attribute ' " << $3 << " ' in struct ' " << $1 << " ' found.Near line number : "<<yylineno;
														$$->type = ERROR;
														sem_flag = 1;
													}

												}
												else
												{
													std::ofstream f;
f.open("Error.txt",std::ofstream::app);
													f << "\nERROR: no struct object ' " << $1 << " ' Exists.Near line number : "<<yylineno;
													$$->type = ERROR;
													sem_flag = 1;
												}
											}		
					| element PTR_OPE element
					| struct_element '.' element 
					| struct_element PTR_OPE element  
					; 


%%

int main(void)
{
	return yyparse();
}

void yyerror(const char *s)
{
	fprintf(stderr,"%s.\n",s);
}

